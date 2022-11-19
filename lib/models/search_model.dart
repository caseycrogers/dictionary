// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:rogers_dictionary/models/translation_mode.dart';
import 'package:rogers_dictionary/pages/bookmarks_page.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'entry_search_model.dart';
import 'translation_model.dart';

class SearchModel {
  SearchModel({
    required this.mode,
    required bool isBookmarksOnly,
  })  : currSelectedEntry = ValueNotifier<SelectedEntry?>(null),
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

  // Keywords for ads.
  final ValueNotifier<List<String>> adKeywords;

  bool get isEnglish => mode == TranslationMode.English;

  bool get hasSelection => currSelectedEntry.value != null;

  bool get isBookmarkedOnly => entrySearchModel.isBookmarkedOnly;

  String get searchString => entrySearchModel.searchString;

  String? get currSelectedHeadword => currSelectedEntry.value?.headword;

  static SearchModel of(BuildContext context) {
    final TranslationModel translationModel = TranslationModel.of(context);
    if (context.findAncestorWidgetOfExactType<BookmarksPage>() != null) {
      return translationModel.bookmarksModel;
    }
    return translationModel.searchModel;
  }
}

class SelectedEntry {
  SelectedEntry({
    required this.headword,
    required this.entry,
    this.referrer,
  });

  final String headword;
  final Future<Entry> entry;
  final SelectedEntryReferrer? referrer;

  @override
  String toString() {
    return 'SelectedEntry($headword)';
  }
}

enum SelectedEntryReferrer {
  relatedHeadword,
  oppositeHeadword,
}
