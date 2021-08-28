import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/util/constants.dart';

class NoResultsWidget extends StatelessWidget {
  const NoResultsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconTheme.merge(
      data: const IconThemeData(
        color: Colors.grey,
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
        child: const _CollapsingScrollEntry(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2 * kPad),
            child: _NoResultsContent(),
          ),
        ),
      ),
    );
  }
}

class _CollapsingScrollEntry extends StatefulWidget {
  const _CollapsingScrollEntry({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _CollapsingScrollEntryState createState() => _CollapsingScrollEntryState();
}

class _CollapsingScrollEntryState extends State<_CollapsingScrollEntry> {
  late final VoidCallback _removeListener;

  bool _shouldInit = true;
  double _height = -1;
  double _pixels = 0;

  double get _progress => min(_pixels / _height, 1);

  void _onScroll() => setState(
        () {
          if (_height == -1) {
            _height = (context.findRenderObject() as RenderBox).size.height;
          }
          _pixels = Scrollable.of(context)!.position.pixels;
        },
      );

  @override
  void didChangeDependencies() {
    if (_shouldInit) {
      final ScrollPosition position = Scrollable.of(context)!.position;
      position.addListener(_onScroll);
      _removeListener = () => position.removeListener(_onScroll);
      _shouldInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: _progress > 0 ? Clip.hardEdge : Clip.none,
      decoration: const BoxDecoration(),
      child: Opacity(
        opacity: (1 - _progress).clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, _pixels / 2),
          child: widget.child,
        ),
      ),
    );
  }
}

class _NoResultsContent extends StatelessWidget {
  const _NoResultsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SearchModel searchPageModel = SearchModel.of(context);
    final String searchHint =
        searchPageModel.entrySearchModel.searchString.isEmpty
            ? i18n.enterTextHint.get(context)
            : i18n.typosHint.get(context);
    return Column(
      children: [
        Text(
          searchPageModel.entrySearchModel.isBookmarkedOnly
              ? i18n.noBookmarksHint.get(context)
              : searchHint,
        ),
        Text(
          searchPageModel.isEnglish
              ? i18n.swipeForSpanish.get(context)
              : i18n.swipeForEnglish.get(context),
        ),
        const Icon(Icons.swipe),
      ],
    );
  }
}
