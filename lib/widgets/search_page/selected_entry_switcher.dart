import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rogers_dictionary/dictionary_navigator/listenable_navigator.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/search_page_model.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';
import 'package:rogers_dictionary/pages/dictionary_page.dart';
import 'package:rogers_dictionary/widgets/dictionary_banner_ad.dart';
import 'package:rogers_dictionary/widgets/search_page/entry_view.dart';

import 'entry_list.dart';

class SelectedEntrySwitcher extends StatelessWidget {
  const SelectedEntrySwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SearchPageModel searchPageModel = _pageModel(context);
    return Provider<SearchPageModel>.value(
      value: searchPageModel,
      builder: (BuildContext context, _) {
        return LayoutBuilder(builder: (context, _) {
          switch (MediaQuery.of(context).orientation) {
            case Orientation.portrait:
              return _PortraitPage(searchPageModel);
            case Orientation.landscape:
              return _LandscapePage(searchPageModel);
          }
        });
      },
    );
  }

  SearchPageModel _pageModel(BuildContext context) {
    final TranslationPageModel t = TranslationPageModel.of(context);
    return DictionaryModel.of(context).currentTab.value ==
            DictionaryTab.search
        ? t.searchPageModel
        : t.bookmarksPageModel;
  }
}

class _PortraitPage extends StatelessWidget {
  const _PortraitPage(this.searchPageModel, {Key? key}) : super(key: key);

  final SearchPageModel searchPageModel;

  @override
  Widget build(BuildContext context) {
    return ListenableNavigator<SelectedEntry?>(
      key: _getKey,
      valueListenable: searchPageModel.currSelectedEntry,
      builder: (BuildContext context, SelectedEntry? selectedEntry, _) =>
          selectedEntry != null
              ? EntryView.asPage(context)
              : EntryList(key: _getKey),
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
          final DictionaryModel dictionaryModel =
              DictionaryModel.readFrom(context);
          dictionaryModel.onTranslationModeChanged(context);
        }
      },
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

class _LandscapePage extends StatelessWidget {
  const _LandscapePage(this.searchPageModel, {Key? key}) : super(key: key);

  final SearchPageModel searchPageModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: EntryList(key: _getKey), flex: 1),
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
