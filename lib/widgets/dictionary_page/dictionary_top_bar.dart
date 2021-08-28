import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/pages/dictionary_page.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/widgets/buttons/help_menu.dart';
import 'package:rogers_dictionary/widgets/buttons/translation_mode_selector.dart';
import 'package:rogers_dictionary/widgets/search_page/search_bar.dart';

const double _horizontalPad = 8;

const Duration _animationSpeed = Duration(milliseconds: 200);

class DictionaryTopBar extends StatelessWidget {
  const DictionaryTopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DictionaryModel dictionaryModel = DictionaryModel.of(context);
    return Container(
      height: kToolbarHeight,
      child: ValueListenableBuilder<TranslationModel>(
        valueListenable: dictionaryModel.translationModel,
        builder: (context, translationPageModel, _) => Material(
          color: primaryColor(translationPageModel.translationMode),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPad,
            ),
            child: Row(
              children: const [
                _TopSearchBar(),
                TranslationModeSelector(),
                Spacer(),
                HelpMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopSearchBar extends StatelessWidget {
  const _TopSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DictionaryTab>(
      valueListenable: DictionaryModel.of(context).currentTab,
      child: const SearchBar(),
      builder: (context, tab, child) {
        return LayoutBuilder(
          builder: (context, _) {
            if (MediaQuery.of(context).orientation == Orientation.portrait) {
              return Container();
            }
            return AnimatedContainer(
              duration: _animationSpeed,
              width: _shouldDisplaySearchBar(context)
                  ? MediaQuery.of(context).size.width * kLandscapeRatio -
                      kToolbarHeight -
                      _horizontalPad +
                      1
                  : 0,
              child: AnimatedSwitcher(
                child: _shouldDisplaySearchBar(context) ? child : Container(),
                duration: _animationSpeed,
                transitionBuilder: (child, animation) {
                  return child;
                },
              ),
            );
          },
        );
      },
    );
  }

  bool _shouldDisplaySearchBar(BuildContext context) {
    return DictionaryModel.of(context).currentTab.value ==
            DictionaryTab.search &&
        MediaQuery.of(context).orientation == Orientation.landscape;
  }
}
