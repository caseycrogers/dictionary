import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/search_page_model.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';
import 'package:rogers_dictionary/pages/dictionary_page.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'package:rogers_dictionary/util/string_utils.dart';

const TranslationMode DEFAULT_TRANSLATION_MODE = TranslationMode.English;

TranslationMode indexToTranslationMode(int index) =>
    TranslationMode.values[index];

int translationModeToIndex(TranslationMode translationMode) {
  return TranslationMode.values.indexOf(translationMode);
}

class DictionaryModel {
  DictionaryModel()
      : currentTab = ValueNotifier(DictionaryTab.search),
        englishPageModel = TranslationPageModel(
          translationMode: TranslationMode.English,
        ),
        spanishPageModel = TranslationPageModel(
          translationMode: TranslationMode.Spanish,
        ) {
    translationPageModel =
        ValueNotifier<TranslationPageModel>(englishPageModel);
    translationPageModel.addListener(() {
      MyApp.analytics.setCurrentScreen(screenName: name);
    });
  }

  final TranslationPageModel englishPageModel;
  final TranslationPageModel spanishPageModel;

  TranslationPageModel pageModel(TranslationMode translationMode) {
    if (translationMode == TranslationMode.English) {
      return englishPageModel;
    }
    return spanishPageModel;
  }

  late final ValueNotifier<TranslationPageModel> translationPageModel;

  final ValueNotifier<DictionaryTab> currentTab;

  final ValueNotifier<double> pageOffset = ValueNotifier(0);

  final ScrollController nestedController = ScrollController();

  TranslationPageModel get _currModel => translationPageModel.value;

  TranslationMode get currTranslationMode =>
      translationPageModel.value.translationMode;

  bool get isEnglish => translationPageModel.value.isEnglish;

  static DictionaryModel of(BuildContext context) => context
      .select<DictionaryModel, DictionaryModel>((DictionaryModel mdl) => mdl);

  static DictionaryModel readFrom(BuildContext context) =>
      context.read<DictionaryModel>();

  TranslationPageModel getPageModel(TranslationMode translationMode) =>
      translationMode == TranslationMode.English
          ? englishPageModel
          : spanishPageModel;

  TranslationPageModel get _oppModel =>
      _currModel.isEnglish ? spanishPageModel : englishPageModel;

  void onTranslationModeChanged(BuildContext context,
      [TranslationMode? newTranslationMode]) {
    translationPageModel.value =
        pageModel(newTranslationMode ?? _oppModel.translationMode);
  }

  void onEntrySelected(BuildContext context, Entry newEntry) =>
      _onHeadwordSelected(
        context,
        newUrlEncodedHeadword: newEntry.headword.urlEncodedHeadword,
        newEntry: newEntry,
        isRelated: false,
        isOppositeHeadword: false,
      );

  void onHeadwordSelected(
    BuildContext context,
    String newUrlEncodedHeadword, {
    bool? isRelated,
  }) {
    _onHeadwordSelected(
      context,
      newUrlEncodedHeadword: newUrlEncodedHeadword,
      isRelated: isRelated ?? false,
      isOppositeHeadword: false,
    );
  }

  void onOppositeHeadwordSelected(
    BuildContext context,
    String newUrlEncodedHeadword,
  ) {
    translationPageModel.value = _oppModel;
    _onHeadwordSelected(
      context,
      newUrlEncodedHeadword: newUrlEncodedHeadword,
      isRelated: false,
      // The depth of an opp headword selection is 1 deeper than a typical
      // selection.
      isOppositeHeadword: true,
    );
  }

  void _onHeadwordSelected(
    BuildContext context, {
    required String newUrlEncodedHeadword,
    required bool isRelated,
    required bool isOppositeHeadword,
    Entry? newEntry,
    SearchPageModel? pageModel,
  }) {
    pageModel ??= isBookmarkedOnly
        ? _currModel.bookmarksPageModel
        : _currModel.searchPageModel;
    // Only update if the value has actually changed
    if (newUrlEncodedHeadword == pageModel.currSelectedHeadword) {
      return;
    }
    if (newUrlEncodedHeadword.isEmpty) {
      pageModel.adKeywords.value = [
        ...pageModel.entrySearchModel.entries
            .getRange(0, min(pageModel.entrySearchModel.entries.length, 3))
            .map((e) => e.headword.headwordText),
      ];
      return pageModel.currSelectedEntry.value = null;
    }
    final FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    final SelectedEntry selectedEntry = SelectedEntry(
      urlEncodedHeadword: newUrlEncodedHeadword,
      entry: newEntry == null
          ? MyApp.db.getEntry(_currModel.translationMode, newUrlEncodedHeadword)
          : Future<Entry>.value(newEntry),
      isRelated: isRelated,
      isOppositeHeadword: isOppositeHeadword,
    );
    pageModel.currSelectedEntry.value = selectedEntry;
    pageModel.adKeywords.value = [
      EntryUtils.urlDecode(selectedEntry.urlEncodedHeadword),
    ];
  }

  bool get isBookmarkedOnly => currentTab.value == DictionaryTab.bookmarks;

  String get name {
    String? thirdTier;
    switch (currentTab.value) {
      case DictionaryTab.search:
        thirdTier =
            translationPageModel.value.searchPageModel.currSelectedHeadword;
        break;
      case DictionaryTab.bookmarks:
        thirdTier =
            translationPageModel.value.searchPageModel.currSelectedHeadword;
        break;
      case DictionaryTab.dialogues:
        thirdTier = translationPageModel
            .value.dialoguesPageModel.selectedChapter?.englishTitle;
        break;
    }
    return '${currTranslationMode.toString().enumString}'
        ' > ${currentTab.value.toString().enumString}'
        ' > ${thirdTier.toString().enumString}';
  }
}
