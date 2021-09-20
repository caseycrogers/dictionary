import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
            _DictionaryTopBar(),
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
        children: const [
          ImplicitNavigatorBackButton(),
          Padding(
            padding: EdgeInsets.all(kPad / 2),
            child: TranslationModeSelector(),
          ),
          Spacer(),
          HelpMenu(),
        ],
      );
    }
    return Container(
        height: kToolbarHeight,
        child: Row(
          children: [
            Row(
              children: const [
                SizedBox(width: kPad),
                _TopSearchBarAndBackButton(),
                SizedBox(width: kPad),
              ],
            ),
            const SizedBox(width: kPad),
            const TranslationModeSelector(),
            const Spacer(),
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
            const SizedBox(width: kPad),
          ],
        ));
  }
}

class _TopSearchBarAndBackButton extends StatelessWidget {
  const _TopSearchBarAndBackButton({Key? key}) : super(key: key);

  double _width(BuildContext context) {
    if (!_shouldDisplaySearchBar(context)) {
      return DictionaryModel.of(context).displayBackButton.value
          ? kToolbarHeight
          : 0;
    }
    return MediaQuery.of(context).size.width *
            kLandscapeLeftFlex /
            (kLandscapeLeftFlex + kLandscapeRightFlex) -
        2 * kPad;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        child: const SearchBar(),
        valueListenable: DictionaryModel.of(context).displayBackButton,
        builder: (context, displayBack, child) {
          return ValueListenableBuilder<DictionaryTab>(
            valueListenable: DictionaryModel.of(context).currentTab,
            builder: (context, tab, _) {
              return Container(
                width: _width(context),
                child: Row(
                  children: [
                    const ImplicitNavigatorBackButton(),
                    Expanded(
                      child: AnimatedSwitcher(
                        child: _shouldDisplaySearchBar(context)
                            ? child!
                            : const SizedBox(),
                        duration: _animationSpeed,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
  }

  bool _shouldDisplaySearchBar(BuildContext context) {
    return DictionaryModel.of(context).currentTab.value ==
            DictionaryTab.search &&
        isBigEnoughForAdvanced(context);
  }
}
