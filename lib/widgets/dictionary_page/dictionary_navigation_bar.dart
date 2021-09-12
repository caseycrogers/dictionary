import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/widgets/adaptive_material/adaptive_material.dart';

import 'dictionary_tab_entry.dart';

class DictionaryNavigationBar extends StatelessWidget {
  const DictionaryNavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveMaterial(
      adaptiveColor: AdaptiveColor.primary,
      child: Container(
        height: kToolbarHeight,
        alignment: Alignment.topCenter,
        child: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelPadding: const EdgeInsets.symmetric(horizontal: 2 * kPad),
          tabs: [
            DictionaryTabEntry(
              index: 0,
              icon: const Icon(Icons.search),
              text: i18n.dictionary.cap.get(context),
            ),
            DictionaryTabEntry(
              index: 1,
              icon: const Icon(Icons.bookmarks_outlined),
              text: i18n.bookmarks.cap.get(context),
            ),
            DictionaryTabEntry(
              index: 2,
              icon: const Icon(Icons.speaker_notes_outlined),
              text: i18n.dialogues.cap.get(context),
            ),
          ],
          isScrollable: true,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
