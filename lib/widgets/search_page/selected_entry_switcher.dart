import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/widgets/translation_mode_switcher.dart';
import 'package:value_navigator/value_navigator.dart';

import 'entry_list.dart';
import 'entry_view.dart';

class SelectedEntrySwitcher extends StatefulWidget {
  const SelectedEntrySwitcher({
    Key? key,
  }) : super(key: key);

  @override
  _SelectedEntrySwitcherState createState() => _SelectedEntrySwitcherState();
}

class _SelectedEntrySwitcherState extends State<SelectedEntrySwitcher> {
  late ValueNavigatorState _valueNavigator;
  VoidCallback? _disposeListener;

  @override
  void didChangeDependencies() {
    if (_disposeListener == null) {
      void onTranslationChanged() {
        if (isCurrentTranslationPage(context)) {
          return _valueNavigator.enable();
        }
        return _valueNavigator.disable();
      }
      DictionaryModel.of(context)
          .translationModel
          .addListener(onTranslationChanged);
      _disposeListener = () => DictionaryModel.of(context)
          .translationModel
          .removeListener(onTranslationChanged);
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _disposeListener?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueNavigator.fromNotifier<SelectedEntry?>(
      // Used to ensure the navigator knows when to display an animation.
      key: _getKey(context),
      valueNotifier: SearchModel.of(context).currSelectedEntry,
      // Ensure that a base page is in the history on opposite headword.
      initialHistory: [
        ValueHistoryEntry(0, null),
      ],
      builder: (context, selectedEntry, _, __) {
        _valueNavigator = ValueNavigator.of<dynamic>(context);
        if (selectedEntry == null) {
          return LayoutBuilder(
            builder: (context, _) {
              if (MediaQuery.of(context).orientation == Orientation.portrait) {
                return EntryList(
                  key: PageStorageKey('${SearchModel.of(context).mode}'
                      '_${SearchModel.of(context).isBookmarkedOnly}'
                      '_entry_list'),
                );
              }
              return Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              );
            },
          );
        }
        return EntryView.asPage(selectedEntry);
      },
      getDepth: (selectedEntry) {
        if (selectedEntry == null) {
          return 0;
        } else if (!selectedEntry.isRelated) {
          return 1;
        }
        return 2;
      },
      onPop: (selectedEntry, prevEntry) {
        if (selectedEntry != null && selectedEntry.isOppositeHeadword) {
          DictionaryModel.of(context).onTranslationModeChanged(context);
        }
      },
    );
  }
}

PageStorageKey _getKey(BuildContext context) {
  final String tabString =
      SearchModel.of(context).isBookmarkedOnly ? 'bookmarks' : 'search';
  return PageStorageKey<String>(
    '$tabString'
    '_selected_entry_listenable_navigator_'
    '${SearchModel.of(context).mode}',
  );
}
