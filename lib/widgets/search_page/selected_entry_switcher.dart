import 'package:flutter/material.dart';

import 'package:rogers_dictionary/dictionary_navigator/listenable_navigator.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/pages/dictionary_page.dart';
import 'package:rogers_dictionary/widgets/search_page/entry_view.dart';

import 'entry_list.dart';

class SelectedEntrySwitcher extends StatelessWidget {
  const SelectedEntrySwitcher({Key? key, this.searchBar}) : super(key: key);

  final Widget? searchBar;

  @override
  Widget build(BuildContext context) {
    final SearchModel searchPageModel = _pageModel(context);
    return LayoutBuilder(
      builder: (context, _) {
        switch (MediaQuery.of(context).orientation) {
          case Orientation.portrait:
            return _PortraitPage(searchPageModel);
          case Orientation.landscape:
            return _LandscapePage(searchPageModel);
        }
      },
    );
  }

  SearchModel _pageModel(BuildContext context) {
    final TranslationModel t = TranslationModel.of(context);
    return DictionaryModel.of(context).currentTab.value == DictionaryTab.search
        ? t.searchPageModel
        : t.bookmarksPageModel;
  }
}

class _PortraitPage extends StatelessWidget {
  const _PortraitPage(this.searchPageModel, {Key? key}) : super(key: key);

  final SearchModel searchPageModel;

  @override
  Widget build(BuildContext context) {
    return ListenableNavigator<SelectedEntry?>(
      // Used to ensure the navigator knows when to display an animation.
      key: const ValueKey('entry_selector'),
      valueListenable: searchPageModel.currSelectedEntry,
      builder: (context, selectedEntry, __) {
        if (selectedEntry == null) {
          return EntryList(key: _getKey(context));
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
          final DictionaryModel dictionaryModel = DictionaryModel.of(context);
          dictionaryModel.onTranslationModeChanged(context);
        }
      },
    );
  }

  PageStorageKey _getKey(BuildContext context) {
    final String tabString =
        searchPageModel.isBookmarkedOnly ? 'bookmarks' : 'search';
    return PageStorageKey<String>(
      '$tabString'
      '_selected_entry_listenable_navigator_'
      '${SearchModel.of(context).mode}',
    );
  }
}

class _LandscapePage extends StatelessWidget {
  const _LandscapePage(this.searchPageModel, {Key? key}) : super(key: key);

  final SearchModel searchPageModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Flexible(
          child: EntryList(key: PageStorageKey('entry_list')),
          flex: 1,
        ),
        Flexible(
          flex: 2,
          child: Row(
            children: [
              const VerticalDivider(width: 1),
              Expanded(
                child: ListenableNavigator<SelectedEntry?>(
                  key: _getKey,
                  valueListenable: searchPageModel.currSelectedEntry,
                  builder:
                      (BuildContext context, SelectedEntry? selectedEntry, _) =>
                          EntryView.asPage(context),
                  getDepth: (selectedEntry) => selectedEntry == null ? 0 : 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PageStorageKey get _getKey {
    final String tabString =
        searchPageModel.isBookmarkedOnly ? 'bookmarks' : 'search';
    return PageStorageKey<String>(
      '${tabString}_selected_entry_listenable_navigator',
    );
  }
}
