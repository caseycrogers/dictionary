import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/models/translation_mode.dart';
import 'package:rogers_dictionary/pages/bookmarks_page.dart';

import 'package:rogers_dictionary/protobufs/entry.pb.dart';

import 'entry_search_model.dart';
import 'translation_model.dart';

class SearchModel {
  SearchModel({
    required this.mode,
    required bool isBookmarksOnly,
  })
      : currSelectedEntry = ValueNotifier<SelectedEntry?>(null),
        entrySearchModel = EntrySearchModel.empty(
          mode,
          isBookmarksOnly,
        ),
        adKeywords = ValueNotifier([]);
  // Translation mode state.
  final TranslationMode mode;

  // Selected entry state.
  final ValueNotifier<SelectedEntry?> currSelectedEntry;

  // Entry search state.
  final EntrySearchModel entrySearchModel;

  // keywords for ads.
  final ValueNotifier<List<String>> adKeywords;

  bool get isEnglish => mode == TranslationMode.English;

  bool get hasSelection => currSelectedEntry.value != null;

  bool get isBookmarkedOnly => entrySearchModel.isBookmarkedOnly;

  String get searchString => entrySearchModel.searchString;

  String? get currSelectedHeadword =>
      currSelectedEntry.value?.urlEncodedHeadword;

  static SearchModel of(BuildContext context) {
    final TranslationModel translationModel = TranslationModel.of(context);
    if (context.findAncestorWidgetOfExactType<BookmarksPage>() != null) {
      return translationModel.bookmarksPageModel;
    }
    return translationModel.searchPageModel;
  }
}

class SelectedEntry {
  SelectedEntry({
    required this.urlEncodedHeadword,
    required this.entry,
    this.referrer,
  });

  final String urlEncodedHeadword;
  final Future<Entry> entry;
  final SelectedEntryReferrer? referrer;

  @override
  String toString() {
    return 'SelectedEntry($urlEncodedHeadword)';
  }
}

enum SelectedEntryReferrer {
  relatedHeadword,
  oppositeHeadword,
}
