import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/entry_database/entry_builders.dart';
import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';

class EntrySearchModel {
  EntrySearchModel._(
    this.currSearchString,
    this._translationMode,
    this._isBookmarkedOnly,
  ) {
    _initializeStream();
    currSearchString.addListener(() {
      _initializeStream();
    });
  }

  EntrySearchModel.empty(
    ValueNotifier<String> currSearchString,
    TranslationMode translationMode,
    bool isBookmarkedOnly,
  ) : this._(currSearchString, translationMode, isBookmarkedOnly);

  final TranslationMode _translationMode;
  final ValueNotifier<String> currSearchString;
  late Stream<Entry> _entryStream;
  LinkedHashSet<Entry> _entries = LinkedHashSet();
  final bool _isBookmarkedOnly;

  String get searchString => currSearchString.value;

  Stream<Entry> get entryStream => _entryStream;

  List<Entry> get entries => _entries.toList();

  bool get isEmpty => currSearchString.value.isEmpty;

  bool get isBookmarkedOnly => _isBookmarkedOnly;

  void resetStream() => _initializeStream();

  void _initializeStream() {
    Stream<Entry> stream;
    // Use a new hashSet to avoid any potential race conditions.
    final LinkedHashSet<Entry> hashSet = LinkedHashSet();
    if (_isBookmarkedOnly) {
      stream = MyApp.db.getBookmarked(_translationMode, startAfter: 0);
    } else {
      if (searchString.isEmpty) {
        stream = const Stream<Entry>.empty();
      }
      stream = MyApp.db.getEntries(
        _translationMode,
        searchString: searchString,
        startAfter: 0,
      );
    }
    _entryStream = stream
        .handleError((Object error, StackTrace stackTrace) =>
            print('ERROR (entry stream): :$error\n$stackTrace'))
        .map(
      (Entry entry) {
        if (!hashSet.add(entry))
          print('WARNING: added duplicate entry '
              '${entry.headword.urlEncodedHeadword}. '
              'Set:\n${hashSet.toList()}');
        return entry;
      },
    ).asBroadcastStream();
    _entries = hashSet;
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
