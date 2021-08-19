import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';

class EntrySearchModel {
  EntrySearchModel._(
    this.currSearchString,
    this._translationMode,
    this._isBookmarkedOnly,
  );

  EntrySearchModel.empty(
    ValueNotifier<String> currSearchString,
    TranslationMode translationMode,
    bool isBookmarkedOnly,
  ) : this._(currSearchString, translationMode, isBookmarkedOnly);

  // Used to expose the current entry list to other widgets.
  List<Entry> entries = [];

  final TranslationMode _translationMode;
  final ValueNotifier<String> currSearchString;
  final bool _isBookmarkedOnly;

  String get searchString => currSearchString.value;

  bool get isEmpty => currSearchString.value.isEmpty;

  bool get isBookmarkedOnly => _isBookmarkedOnly;

  Stream<Entry> newStream({int startAt = 0}) {
    if (_isBookmarkedOnly) {
      return MyApp.db.getBookmarked(_translationMode, startAt: 0);
    }
    if (searchString.isEmpty) {
      return const Stream<Entry>.empty();
    }
    return MyApp.db
        .getEntries(
      _translationMode,
      searchString: searchString,
      startAt: startAt,
    )
        .handleError(
      (Object error, StackTrace stackTrace) {
        print('ERROR (entry stream): $error\n$stackTrace');
      },
    );
  }

  void onSearchStringChanged({
    required BuildContext context,
    required String newSearchString,
  }) {
    MyApp.analytics.logSearch(searchTerm: newSearchString);
    DictionaryModel.readFrom(context).onHeadwordSelected(
      context,
      '',
    );
    currSearchString.value = newSearchString;
  }
}
