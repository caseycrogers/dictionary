import 'package:flutter/material.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';

import 'package:rogers_dictionary/pages/dictionary_page.dart';
import 'package:rogers_dictionary/util/constants.dart';
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
        switch (MediaQuery.of(context).orientation) {
          case Orientation.portrait:
            return const _PortraitPage();
          case Orientation.landscape:
            return const _LandscapePage();
        }
      },
    );
  }
}

class _PortraitPage extends StatelessWidget {
  const _PortraitPage({
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

class _LandscapePage extends StatelessWidget {
  const _LandscapePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TranslationModeSwitcher(
          child: Row(
            children: [
              const Flexible(
                child: EntryList(key: PageStorageKey('entry_list')),
                flex: kLandscapeLeftFlex,
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
