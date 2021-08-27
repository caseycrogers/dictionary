import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/clients/speech_to_text.dart';
import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';

class EntrySearchModel {
  EntrySearchModel._(
    this._translationMode,
    this._isBookmarkedOnly,
  );

  EntrySearchModel.empty(
    TranslationMode translationMode,
    bool isBookmarkedOnly,
  ) : this._(translationMode, isBookmarkedOnly);

  // Static so that these are shared between both modes
  static final ValueNotifier<String> _currSearchString = ValueNotifier('');
  static final ValueNotifier<Stream<RecordingUpdate>?> _currSpeechToTextStream =
      ValueNotifier(null);

  // Used to expose the current entry list to other widgets.
  List<Entry> entries = [];

  final TranslationMode _translationMode;
  final bool _isBookmarkedOnly;

  ValueNotifier<String> get currSearchString => _currSearchString;

  ValueNotifier<Stream<RecordingUpdate>?> get currSpeechToTextStream =>
      _currSpeechToTextStream;

  String get searchString => currSearchString.value;

  bool get isEmpty => currSearchString.value.isEmpty;

  bool get isBookmarkedOnly => _isBookmarkedOnly;

  Stream<Entry> newStream({int startAt = 0}) {
    if (_isBookmarkedOnly) {
      return DictionaryApp.db.getBookmarked(_translationMode, startAt: startAt);
    }
    return DictionaryApp.db
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

  bool isDirty() {
    return _isBookmarkedOnly &&
        DictionaryApp.db.areBookmarksDirty(_translationMode);
  }

  void onSearchStringChanged({
    required BuildContext context,
    required String newSearchString,
  }) {
    DictionaryApp.analytics.logSearch(searchTerm: newSearchString);
    DictionaryModel.readFrom(context).onHeadwordSelected(
      context,
      '',
    );
    currSearchString.value = newSearchString;
  }
}
