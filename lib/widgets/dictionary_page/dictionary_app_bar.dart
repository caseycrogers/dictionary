import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:implicit_navigator/implicit_navigator.dart';

import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/util/layout_picker.dart';
import 'package:rogers_dictionary/widgets/adaptive_material/adaptive_material.dart';
import 'package:rogers_dictionary/widgets/buttons/help_menu.dart';
import 'package:rogers_dictionary/widgets/buttons/translation_mode_selector.dart';
import 'package:rogers_dictionary/widgets/dictionary_banner_ad.dart';
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
        title: Column(
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _horizontalPad),
              child: _DictionaryTopBar(),
            ),
          ],
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                SizedBox(
                  width: kToolbarHeight,
                  child: ImplicitNavigatorBackButton(),
                ),
                _TopSearchBar(),
                Padding(
                  padding: EdgeInsets.all(kPad / 2),
                  child: TranslationModeSelector(),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const DictionaryTabBar(indicator: false),
                const SizedBox(width: 2),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: kPad),
                  width: 1,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(.5),
                  ),
                ),
                const HelpMenu(),
              ],
            ),
          ],
        ));
  }
}

class _TopSearchBar extends StatelessWidget {
  const _TopSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return ValueListenableBuilder<DictionaryTab>(
      valueListenable: DictionaryModel.of(context).currentTab,
      child: const SearchBar(),
      builder: (context, tab, child) {
        return AnimatedContainer(
          width: _shouldDisplaySearchBar(context)
              ? size.width *
                      (kLandscapeLeftFlex /
                          (kLandscapeLeftFlex + kLandscapeRightFlex)) -
                  kToolbarHeight -
                  kPad
              : 0,
          child: AnimatedSwitcher(
            child: _shouldDisplaySearchBar(context)
                ? child!
                : const SizedBox(),
            duration: _animationSpeed,
          ),
          duration: _animationSpeed,
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
