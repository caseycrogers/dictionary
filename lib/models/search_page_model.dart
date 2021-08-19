import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rogers_dictionary/main.dart';

import 'package:rogers_dictionary/protobufs/entry.pb.dart';

import 'entry_search_model.dart';
import 'translation_page_model.dart';

class SearchPageModel {
  SearchPageModel({
    required this.translationMode,
    required bool isBookmarkedOnly,
  })  : currSelectedEntry = ValueNotifier<SelectedEntry?>(null),
        entrySearchModel = EntrySearchModel.empty(
          _currSearchString,
          translationMode,
          isBookmarkedOnly,
        ),
        adKeywords = ValueNotifier([]) {
    MyApp.db.isBookmarksDirty(translationMode).addListener(() {
      if (MyApp.db.isBookmarksDirty(translationMode).value == true) {
        //entrySearchModel.reset();
      }
    });
    _currSearchString.addListener(() {
      if (_currSearchString.value.isNotEmpty) {
        currSelectedEntry.value = null;
      }
    });
  }

  // Translation mode state.
  final TranslationMode translationMode;

  // Selected entry state.
  final ValueNotifier<SelectedEntry?> currSelectedEntry;

  // Entry search state.
  final EntrySearchModel entrySearchModel;

  // keywords for ads.
  final ValueNotifier<List<String>> adKeywords;

  static final ValueNotifier<String> _currSearchString = ValueNotifier('');

  bool get isEnglish => translationMode == TranslationMode.English;

  bool get hasSelection => currSelectedEntry.value != null;

  bool get isBookmarkedOnly => entrySearchModel.isBookmarkedOnly;

  String get searchString => entrySearchModel.searchString;

  String? get currSelectedHeadword =>
      currSelectedEntry.value?.urlEncodedHeadword;

  static SearchPageModel of(BuildContext context) =>
      context.watch<SearchPageModel>();

  static SearchPageModel readFrom(BuildContext context) =>
      context.read<SearchPageModel>();
}

class SelectedEntry {
  SelectedEntry({
    required this.urlEncodedHeadword,
    required this.entry,
    bool? isRelated,
    bool? isOppositeHeadword,
  })  : isRelated = isRelated ?? false,
        isOppositeHeadword = isOppositeHeadword ?? false;

  final String urlEncodedHeadword;
  final Future<Entry> entry;
  final bool isRelated;
  final bool isOppositeHeadword;

  @override
  String toString() {
    return 'SelectedEntry($urlEncodedHeadword)';
  }
}
