import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:path/path.dart';

import 'package:rogers_dictionary/entry_database/database_constants.dart';
import 'package:rogers_dictionary/entry_database/entry_builders.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';
import 'package:rogers_dictionary/protobufs/database_version.pb.dart';
import 'package:rogers_dictionary/protobufs/dialogues.pb.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';

// A database interface for fetching dictionary entries.
abstract class DictionaryDatabase {
  DictionaryDatabase()
      : _englishBookmarksCache = {},
        _spanishBookmarksCache = {};

  Future<DatabaseVersion> get version => rootBundle
      .loadString(join('assets', '$VERSION_FILE'))
      .then((v) => VersionUtils.fromString(v));

  /// Indicates whether or not the bookmarks list may have changes since it was
  /// last fetched.
  final ValueNotifier<bool> _englishIsBookmarksDirty = ValueNotifier(true);
  final ValueNotifier<bool> _spanishIsBookmarksDirty = ValueNotifier(true);

  ValueNotifier<bool> isBookmarksDirty(TranslationMode translationMode) {
    if (translationMode == TranslationMode.English) {
      return _englishIsBookmarksDirty;
    }
    return _spanishIsBookmarksDirty;
  }

  void _updateDirtyBookmarks(TranslationMode translationMode, bool isDirty) {
    isBookmarksDirty(translationMode).value = isDirty;
  }

  final Map<String, bool> _englishBookmarksCache;
  final Map<String, bool> _spanishBookmarksCache;

  // Fetch entries from the database.
  Stream<Entry> getEntries(
    TranslationMode translationMode, {
    required String searchString,
    required int startAt,
  });

  // Get the given entry from the database.
  Future<Entry> getEntry(
      TranslationMode translationMode, String urlEncodedHeadword);

  @mustCallSuper
  Future<bool> setBookmark(TranslationMode translationMode,
      String urlEncodedHeadword, bool bookmark) {
    final bool? oldValue = _getCache(translationMode)[urlEncodedHeadword];
    if (oldValue != null && oldValue != bookmark) {
      // Only dirty the cache if we're actually changing the value.
      _updateDirtyBookmarks(translationMode, true);
    }
    return Future<bool>.value(
      _getCache(translationMode)[urlEncodedHeadword] = bookmark,
    );
  }

  @mustCallSuper
  Stream<Entry> getBookmarked(TranslationMode translationMode,
      {required int startAt}) {
    _updateDirtyBookmarks(translationMode, false);
    return const Stream.empty();
  }

  bool isBookmarked(
      TranslationMode translationMode, String urlEncodedHeadword) {
    assert(
      _getCache(translationMode).containsKey(urlEncodedHeadword),
      'Could not find \'$urlEncodedHeadword\' in the favorites cache.',
    );
    return _getCache(translationMode)[urlEncodedHeadword]!;
  }

  Stream<DialogueChapter> getDialogues({
    int startAt,
  });

  Map<String, bool> _getCache(TranslationMode translationMode) =>
      translationMode == TranslationMode.English
          ? _englishBookmarksCache
          : _spanishBookmarksCache;
}
