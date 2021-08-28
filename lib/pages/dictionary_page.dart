import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/pages/dialogues_page.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/util/string_utils.dart';
import 'package:rogers_dictionary/widgets/dialogues_page/dictionary_back_button.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab_bar_view.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab_entry.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_top_bar.dart';

import 'bookmarks_page.dart';
import 'search_page.dart';

enum DictionaryTab {
  search,
  bookmarks,
  dialogues,
}

String dictionaryTabName(DictionaryTab dictionaryTab) =>
    dictionaryTab.toString().enumString;

class DictionaryPage extends StatefulWidget {
  @override
  _DictionaryPageState createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  @override
  Widget build(BuildContext context) {
    final DictionaryModel dictionaryModel = DictionaryModel.of(context);
    return ValueListenableBuilder<TranslationModel>(
      valueListenable: dictionaryModel.translationModel,
      child: DictionaryTabBarView(
        children: LinkedHashMap.from(<DictionaryTab, Widget>{
          DictionaryTab.search: SearchPage(),
          DictionaryTab.bookmarks: BookmarksPage(),
          DictionaryTab.dialogues: DialoguesPage(),
        }),
      ),
      builder: (context, translationPageModel, tabBarView) => Scaffold(
        body: Column(
          children: [
            AppBar(
              leading: const DictionaryBackButton(),
              elevation: kGroundElevation,
              titleSpacing: 0,
              title: const DictionaryTopBar(),
              backgroundColor:
                  primaryColor(translationPageModel.translationMode),
            ),
            Expanded(
              child: tabBarView!,
            ),
            Material(
              color: primaryColor(translationPageModel.translationMode),
              child: Container(
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom),
                child: MediaQuery(
                  data:
                      MediaQuery.of(context).removePadding(removeBottom: true),
                  child: Container(
                    child: TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 2 * kPad),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
