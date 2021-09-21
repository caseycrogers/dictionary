import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:implicit_navigator/implicit_navigator.dart';

import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/dictionary_app.dart';
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/models/translation_mode.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'package:rogers_dictionary/util/string_utils.dart';
import 'package:rogers_dictionary/util/value_notifier_extension.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab.dart';

const TranslationMode DEFAULT_TRANSLATION_MODE = TranslationMode.English;

TranslationMode indexToTranslationMode(int index) =>
    TranslationMode.values[index];

int translationModeToIndex(TranslationMode translationMode) {
  return TranslationMode.values.indexOf(translationMode);
}

class DictionaryModel {
  DictionaryModel()
      : currentTab = ValueNotifier(DictionaryTab.search),
        englishPageModel = TranslationModel(
          translationMode: TranslationMode.English,
        ),
        spanishPageModel = TranslationModel(
          translationMode: TranslationMode.Spanish,
        ) {
    translationModel = ValueNotifier<TranslationModel>(englishPageModel);
    translationModel.addListener(() {
      DictionaryApp.analytics.setCurrentScreen(screenName: name);
    });
  }

  static late final DictionaryModel _instance = DictionaryModel();

  final TranslationModel englishPageModel;
  final TranslationModel spanishPageModel;

  TranslationModel translationModelFor(TranslationMode mode) {
    if (mode == TranslationMode.English) {
      return englishPageModel;
    }
    return spanishPageModel;
  }

  late final ValueNotifier<TranslationModel> translationModel;

  final ValueNotifier<DictionaryTab> currentTab;

  final ValueNotifier<double> pageOffset = ValueNotifier(0);

  final ValueNotifier<bool> displayBackButton = ValueNotifier(false);

  late ImplicitNavigatorState<DictionaryTab> tabNavigator;

  ValueNotifier<List<String>> get currentAdKeywords {
    return currentTab.expand<List<String>>((tab) {
      switch (tab) {
        case DictionaryTab.search:
          return currTranslationModel.searchModel.adKeywords;
        case DictionaryTab.bookmarks:
          return currTranslationModel.bookmarksPageModel.adKeywords;
        case DictionaryTab.dialogues:
          // There are no ad keywords for the dialogues page.
          return ValueNotifier([]);
      }
    });
  }

  final ScrollController nestedController = ScrollController();

  TranslationModel get currTranslationModel => translationModel.value;

  TranslationMode get currTranslationMode =>
      translationModel.value.translationMode;

  bool get isEnglish => translationModel.value.isEnglish;

  static DictionaryModel of(BuildContext context) {
    return _instance;
  }

  TranslationModel getPageModel(TranslationMode translationMode) =>
      isEnglish ? englishPageModel : spanishPageModel;

  TranslationModel get _oppModel =>
      currTranslationModel.isEnglish ? spanishPageModel : englishPageModel;

  void onTranslationModeChanged(BuildContext context,
      [TranslationMode? newTranslationMode]) {
    translationModel.value =
        translationModelFor(newTranslationMode ?? _oppModel.translationMode);
  }

  void onEntrySelected(BuildContext context, Entry newEntry) =>
      _onEntrySelected(
        context,
        newUrlEncodedHeadword: newEntry.headword.urlEncodedHeadword,
        newEntry: newEntry,
      );

  void onHeadwordSelected(
    BuildContext context,
    String newUrlEncodedHeadword, {
    SelectedEntryReferrer? referrer,
  }) {
    _onEntrySelected(
      context,
      newUrlEncodedHeadword: newUrlEncodedHeadword,
      referrer: referrer,
    );
  }

  void onOppositeHeadwordSelected(
    BuildContext context,
    String newUrlEncodedHeadword,
  ) {
    translationModel.value = _oppModel;
    _onEntrySelected(
      context,
      newUrlEncodedHeadword: newUrlEncodedHeadword,
      referrer: SelectedEntryReferrer.oppositeHeadword,
    );
  }

  void _onEntrySelected(
    BuildContext context, {
    required String newUrlEncodedHeadword,
    SelectedEntryReferrer? referrer,
    Entry? newEntry,
    SearchModel? pageModel,
  }) {
    pageModel ??= isBookmarksOnly
        ? currTranslationModel.bookmarksPageModel
        : currTranslationModel.searchModel;
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
          ? DictionaryApp.db.getEntry(
              currTranslationModel.translationMode, newUrlEncodedHeadword)
          : Future<Entry>.value(newEntry),
      referrer: referrer,
    );
    pageModel.currSelectedEntry.value = selectedEntry;
    pageModel.adKeywords.value = [
      EntryUtils.urlDecode(selectedEntry.urlEncodedHeadword),
    ];
  }

  bool get isBookmarksOnly => currentTab.value == DictionaryTab.bookmarks;

  String get name {
    String? thirdTier;
    switch (currentTab.value) {
      case DictionaryTab.search:
        thirdTier = translationModel.value.searchModel.currSelectedHeadword;
        break;
      case DictionaryTab.bookmarks:
        thirdTier = translationModel.value.searchModel.currSelectedHeadword;
        break;
      case DictionaryTab.dialogues:
        thirdTier = translationModel
            .value.dialoguesPageModel.selectedChapter?.englishTitle;
        break;
    }
    return '${currTranslationMode.toString().enumString}'
        ' > ${currentTab.value.toString().enumString}'
        ' > ${thirdTier.toString().enumString}';
  }
}
