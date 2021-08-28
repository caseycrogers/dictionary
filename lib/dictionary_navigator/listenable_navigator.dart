import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/pages/default_page.dart';
import 'package:rogers_dictionary/util/map_utils.dart';
import 'package:rogers_dictionary/util/string_utils.dart';

class ListenableNavigator<T> extends StatefulWidget {
  const ListenableNavigator({
    required Key key,
    required this.valueListenable,
    required this.builder,
    required this.getDepth,
    this.child,
    this.transitionBuilder,
    this.duration,
    this.onPopCallback,
  }) : super(key: key);

  static final Map<int, _ListenableNavigatorState> navigatorStack =
      SplayTreeMap();

  static bool get isEmpty {
    if (navigatorStack.isEmpty) {
      return true;
    }
    return navigatorStack.values.every((navigator) => navigator.isEmpty);
  }

  static void _updateEmptyNotifier() {
    Future<void>.delayed(Duration.zero).whenComplete(() {
      emptyNotifier.value = isEmpty;
    });
  }

  static ValueNotifier<bool> emptyNotifier = ValueNotifier(true);

  final ValueNotifier<T> valueListenable;
  final ValueWidgetBuilder<T> builder;
  final int Function(T) getDepth;

  final Widget? child;
  final RouteTransitionsBuilder? transitionBuilder;
  final Duration? duration;

  final void Function(T?)? onPopCallback;

  @override
  _ListenableNavigatorState<T> createState() => _ListenableNavigatorState<T>();

  static Future<bool> pop({bool isSystem = true}) async {
    await DictionaryApp.analytics.logEvent(
      name: 'pop${isSystem ? '_system' : ''}',
      parameters: {
        'stack': navigatorStack.map(
          (depth, nav) {
            return MapEntry(
                depth.toString(),
                nav.stack.map<String, String>((key, dynamic value) {
                  return MapEntry(
                      key.toString(), value.toString().truncated(20));
                }).toString());
          },
        ).toString(),
      },
    );
    // Iterate from the deepest to the highest listenable navigator.
    for (final _ListenableNavigatorState navigatorState
        in navigatorStack.values.toList().reversed) {
      final bool willPop = await navigatorState._onWillPop();
      if (!willPop) {
        // We have reached a listenable navigator that consumed the pop.
        return false;
      }
    }
    // No listenable navigators consumed the pop, pop the topmost navigator.
    return true;
  }
}

class _ListenableNavigatorState<T> extends State<ListenableNavigator<T>> {
  static final Map<Key, SplayTreeMap<int, Object?>> stackCache = {};

  VoidCallback? analyticsListener;

  late final bool isPrimary;

  late final Map<int, T> stack = stackCache.getOrElse(
    widget.key ?? ValueKey(widget.hashCode),
    SplayTreeMap<int, T>(),
  ) as SplayTreeMap<int, T>;

  _ListenableNavigatorState? get parent {
    return context.findAncestorStateOfType<_ListenableNavigatorState>();
  }

  bool get isEmpty {
    return stack.length <= 1;
  }

  int get depth {
    return (parent?.depth ?? -1) + 1;
  }

  @override
  void initState() {
    // This listenable navigator is the primary one if it's the first built.
    isPrimary = ListenableNavigator.navigatorStack.isEmpty;
    ListenableNavigator.navigatorStack[depth] = this;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    analyticsListener ??= () {
      DictionaryApp.analytics
          .setCurrentScreen(screenName: DictionaryModel.of(context).name);
    };
    widget.valueListenable.addListener(analyticsListener!);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    ListenableNavigator.navigatorStack.removeWhere((_, value) => value == this);
    ListenableNavigator._updateEmptyNotifier();
    if (analyticsListener != null) {
      widget.valueListenable.removeListener(analyticsListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Only add a pop scope if this is the primary navigator so that this
      // navigator alone can handle pops.
      onWillPop: isPrimary ? ListenableNavigator.pop : null,
      child: ValueListenableBuilder<T>(
        valueListenable: widget.valueListenable,
        child: widget.child,
        builder: (BuildContext context, T value, Widget? child) {
          final int depth = widget.getDepth(value);
          if (stack.isEmpty) {
            assert(
              depth == 0,
              'Depth of initial value must be 0. '
              'Value: $value. Depth: $depth',
            );
          }
          stack.removeWhere((key, _) => key >= depth);
          if (stack[depth] == null) {
            stack[depth] = value;
          }
          ListenableNavigator._updateEmptyNotifier();
          return Navigator(
            pages: _pages(context),
            onPopPage: (route, dynamic result) {
              throw UnsupportedError(
                'ListenableNavigators should never be popped directly.',
              );
            },
          );
        },
      ),
    );
  }

  List<DefaultPage> _pages(BuildContext context) {
    return stack.values
        .map(
          (value) => DefaultPage(
            key: ValueKey(value),
            child: widget.builder(context, value, widget.child),
            transitionsBuilder: widget.transitionBuilder,
            dictionaryModel: DictionaryModel.of(context),
          ),
        )
        .toList();
  }

  Future<bool> _onWillPop() {
    if (stack.length == 1) {
      // This navigator is empty, propagate the pop upwards.
      return Future.value(true);
    }
    // Remove the top item in the stack
    final T value = stack.remove(stack.keys.last)!;
    final T oldValue = stack.values.last;
    widget.valueListenable.value = oldValue;
    widget.onPopCallback?.call(value);
    // Return false to veto the pop because it was handled internally.
    return Future.value(false);
  }
}
