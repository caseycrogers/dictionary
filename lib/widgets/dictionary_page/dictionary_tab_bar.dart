import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/util/collection_utils.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/widgets/adaptive_material/adaptive_material.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab.dart';

class DictionaryTabBar extends StatelessWidget {
  const DictionaryTabBar({Key? key, this.indicator = true}) : super(key: key);

  final bool indicator;

  @override
  Widget build(BuildContext context) {
    return AdaptiveMaterial(
      adaptiveColor: AdaptiveColor.primary,
      child: Container(
        height: kToolbarHeight,
        alignment: Alignment.topCenter,
        child: TabBar(
          labelColor: AdaptiveMaterial.onColorOf(context),
          labelPadding: const EdgeInsets.symmetric(horizontal: 2 * kPad),
          tabs: DictionaryTab.values.asMap().mapDown((index, tab) {
            return DictionaryTabEntry(
              index: index,
              icon: Icon(tabToIcon(tab)),
              text: tabToText(context, tab),
            );
          }).toList(),
          isScrollable: true,
          indicator: indicator
              ? const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                )
              : const BoxDecoration(),
        ),
      ),
    );
  }
}
