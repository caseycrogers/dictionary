import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/dictionary_app.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/translation_mode.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'package:rogers_dictionary/util/layout_picker.dart';

class EntrySearchModel {
  EntrySearchModel._(this._translationMode,
      this._isBookmarkedOnly,);

  EntrySearchModel.empty(TranslationMode translationMode,
      bool isBookmarkedOnly,) : this._(translationMode, isBookmarkedOnly);

  // Static so that this is shared between both modes
  static final ValueNotifier<String> _currSearchString = ValueNotifier('');

  // Used to expose the current entry list to other widgets.
  List<Entry> entries = [];

  final TranslationMode _translationMode;
  final bool _isBookmarkedOnly;

  ValueNotifier<String> get currSearchString => _currSearchString;

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
    if (newSearchString == currSearchString.value) {
      // Value hasn't changed, don't update.
      return;
    }
    DictionaryApp.analytics.logSearch(searchTerm: newSearchString);
    if (!isBigEnoughForAdvanced(context)) {
      DictionaryModel.of(context).onHeadwordSelected(context, '');
    }
    currSearchString.value = newSearchString;
  }
}
