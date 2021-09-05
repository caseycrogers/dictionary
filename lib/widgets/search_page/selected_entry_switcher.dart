import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/dictionary_navigator/listenable_navigator.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/search_model.dart';

import 'entry_list.dart';
import 'entry_view.dart';

class SelectedEntrySwitcher extends StatelessWidget {
  const SelectedEntrySwitcher({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableNavigator<SelectedEntry?>(
      // Used to ensure the navigator knows when to display an animation.
      key: _getKey(context),
      valueListenable: SearchModel.of(context).currSelectedEntry,
      builder: (context, selectedEntry, __) {
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
        return EntryView.asPage(context);
      },
      getDepth: (selectedEntry) {
        if (selectedEntry == null) {
          return 0;
        } else if (!selectedEntry.isRelated) {
          return 1;
        }
        return 2;
      },
      onPopCallback: (selectedEntry) {
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
