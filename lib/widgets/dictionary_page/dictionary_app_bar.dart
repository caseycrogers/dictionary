import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:implicit_navigator/implicit_navigator.dart';

import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/util/layout_picker.dart';
import 'package:rogers_dictionary/widgets/adaptive_material/adaptive_material.dart';
import 'package:rogers_dictionary/widgets/buttons/help_menu.dart';
import 'package:rogers_dictionary/widgets/buttons/translation_mode_selector.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab.dart';
import 'package:rogers_dictionary/widgets/search_page/search_bar.dart';

import 'dictionary_tab_bar.dart';

const double _horizontalPad = 8;

const Duration _animationSpeed = Duration(milliseconds: 200);

class DictionaryAppBar extends StatelessWidget {
  const DictionaryAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveMaterial(
      adaptiveColor: AdaptiveColor.primary,
      child: AppBar(
        leadingWidth: 0,
        elevation: kGroundElevation,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPad),
          child: _DictionaryTopBar(),
        ),
      ),
    );
  }
}

class _DictionaryTopBar extends StatelessWidget {
  const _DictionaryTopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isBigEnoughForAdvanced(context)) {
      return Row(
        children: [
          Container(
            width: kToolbarHeight,
            height: kToolbarHeight,
            child: const ImplicitNavigatorBackButton(),
          ),
          const Padding(
            padding: EdgeInsets.all(kPad / 2),
            child: TranslationModeSelector(),
          ),
          const Spacer(),
          const HelpMenu(),
        ],
      );
    }
    return Container(
        height: kToolbarHeight,
        child: Row(
          children: [
            Flexible(
              flex: kLandscapeLeftFlex,
              child: Row(
                children: [
                  Container(
                    width: kToolbarHeight,
                    child: const ImplicitNavigatorBackButton(),
                  ),
                  const Expanded(child: _TopSearchBar()),
                ],
              ),
            ),
            Flexible(
              flex: kLandscapeRightFlex,
              child: Row(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(kPad / 2),
                    child: TranslationModeSelector(),
                  ),
                  Spacer(),
                  DictionaryTabBar(indicator: false),
                  HelpMenu(),
                ],
              ),
            ),
          ],
        ));
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
          builder: (context, constraints) {
            return AnimatedContainer(
              duration: _animationSpeed,
              width:
                  _shouldDisplaySearchBar(context) ? constraints.maxWidth : 0,
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
        isBigEnoughForAdvanced(context);
  }
}
