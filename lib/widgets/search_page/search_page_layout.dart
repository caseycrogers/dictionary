import 'package:flutter/material.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/search_model.dart';

import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/util/layout_picker.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab.dart';
import 'package:rogers_dictionary/widgets/search_page/search_bar.dart';
import 'package:rogers_dictionary/widgets/search_page/selected_entry_switcher.dart';
import 'package:rogers_dictionary/widgets/translation_mode_switcher.dart';

import 'entry_list.dart';

class SearchPageLayout extends StatelessWidget {
  const SearchPageLayout({
    Key? key,
    this.searchBar,
  }) : super(key: key);

  final Widget? searchBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        if (isBigEnoughForAdvanced(context)) {
          return const _LandscapeLayout();
        }
        return const _PortraitLayout();
      },
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TranslationModeSwitcher(
      header: _isSearch(context) ? const SearchBar() : null,
      child: const SelectedEntrySwitcher(),
    );
  }
}

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TranslationModeSwitcher(
          child: Row(
            children: [
              Flexible(
                flex: kLandscapeLeftFlex,
                child: Container(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      // We need the builder to get [SearchModel] below.
                      return EntryList(
                        key: PageStorageKey(
                          '${SearchModel.of(context).mode}'
                          '_${SearchModel.of(context).isBookmarkedOnly}'
                          '_entry_list',
                        ),
                      );
                    },
                  ),
                ),
              ),
              Flexible(
                flex: kLandscapeRightFlex,
                child: Row(
                  children: const [
                    VerticalDivider(width: 1),
                    Expanded(
                      child: SelectedEntrySwitcher(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool _isSearch(BuildContext context) {
  return DictionaryModel.of(context).currentTab.value == DictionaryTab.search;
}
