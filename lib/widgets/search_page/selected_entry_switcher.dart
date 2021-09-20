import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:implicit_navigator/implicit_navigator.dart';

import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/util/layout_picker.dart';
import 'package:rogers_dictionary/widgets/translation_mode_switcher.dart';

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
  ImplicitNavigatorState<SelectedEntry?>? _navigator;

  @override
  void initState() {
    super.initState();
    DictionaryModel.of(context)
        .translationModel
        .addListener(_onTranslationModeChanged);
  }

  @override
  void dispose() {
    DictionaryModel.of(context)
        .translationModel
        .removeListener(_onTranslationModeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ImplicitNavigator<SelectedEntry?>.fromNotifier(
      // Used to ensure the navigator knows when to display an animation.
      key: _getKey(context),
      valueNotifier: SearchModel.of(context).currSelectedEntry,
      // Ensure that a base page is in the history on opposite headword.
      initialHistory: const [
        ValueHistoryEntry(0, null),
      ],
      builder: (context, selectedEntry, _, __) {
        _navigator = ImplicitNavigator.of<SelectedEntry?>(context);
        if (selectedEntry == null) {
          if (isBigEnoughForAdvanced(context)) {
            return Container(
              color: Theme.of(context).colorScheme.background,
            );
          }
          return EntryList(
            key: PageStorageKey('${SearchModel.of(context).mode}'
                '_${SearchModel.of(context).isBookmarkedOnly}'
                '_entry_list'),
          );
        }
        return EntryView.asPage(selectedEntry);
      },
      getDepth: (selectedEntry) {
        if (selectedEntry == null) {
          return 0;
        }
        switch (selectedEntry.referrer) {
          case null:
            return 1;
          case SelectedEntryReferrer.oppositeHeadword:
            return 2;
          case SelectedEntryReferrer.relatedHeadword:
            return null;
        }
      },
      onPop: (selectedEntry, prevEntry) {
        if (selectedEntry != null &&
            selectedEntry.referrer == SelectedEntryReferrer.oppositeHeadword) {
          DictionaryModel.of(context).onTranslationModeChanged(context);
        }
      },
    );
  }

  void _onTranslationModeChanged() {
    _navigator!.canPop = isCurrentTranslationPage(context);
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
