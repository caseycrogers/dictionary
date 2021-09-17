import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart';

import 'package:rogers_dictionary/clients/database_constants.dart';
import 'package:rogers_dictionary/clients/dictionary_database/dictionary_database.dart';
import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/models/translation_mode.dart';
import 'package:rogers_dictionary/protobufs/database_version.pb.dart';
import 'package:rogers_dictionary/protobufs/dialogues.pb.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'package:rogers_dictionary/util/string_utils.dart';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SqfliteDatabase extends DictionaryDatabase {
  SqfliteDatabase() {
    _initialize();
  }

  late final String _databasesPath;
  late final String _path;
  late final String _bookmarksPath;
  late final DatabaseVersion _version;
  final Completer<Database> _dbCompleter = Completer();

  Future<Database> get _dbFuture => _dbCompleter.future;

  Future<void> _initialize() async {
    _databasesPath = await _getDatabasePath();

    // Manually inject proper slash, don't use join it breaks on Windows.
    _version = VersionUtils.fromString(
      await rootBundle.loadString('assets/$VERSION_FILE'),
    );
    _path = join(
      _databasesPath,
      '${DICTIONARY_DB}V${_version.versionString}.db',
    );
    _bookmarksPath = join(
      _databasesPath,
      '$BOOKMARKS_DB.db',
    );
    _dbCompleter.complete(_getDatabase());
  }

  // We need an int that represents no string match and is smaller than any
  // conceivable real string match
  static const int NO_MATCH = 100000;

  String _relevancyScore(String searchString, String columnName) {
    final String index =
        '''INSTR(LOWER(' ' || $columnName), LOWER(' $searchString'))''';
    return '''CASE 
    WHEN $index = 0
    THEN $NO_MATCH
    ELSE 1000*INSTR(SUBSTR(' ' || $columnName || ' ', $index + ${searchString.length + 1}), ' ') + LENGTH($columnName)
    END''';
  }

  @override
  Stream<Entry> getEntries(
    TranslationMode translationMode, {
    required String searchString,
    required int startAt,
  }) =>
      _getEntries(
        translationMode,
        rawSearchString: searchString,
        startAt: startAt,
        isBookmarkedOnly: false,
      );

  @override
  Future<Entry> getEntry(
      TranslationMode translationMode, String urlEncodedHeadword) async {
    final Database db = await _dbFuture;
    final Entry entry = _rowToEntry(
      urlEncodedHeadword,
      translationMode,
      await db.rawQuery('''
 SELECT *,
        EXISTS(SELECT $URL_ENCODED_HEADWORD
               FROM ${entryTable(translationMode)}
               WHERE $URL_ENCODED_HEADWORD =
                 ${bookmarksTable(translationMode)}.$URL_ENCODED_HEADWORD) AS $IS_FAVORITE
 FROM ${entryTable(translationMode)}
 WHERE $URL_ENCODED_HEADWORD = '$urlEncodedHeadword';''').then((List<
                  Map<String, Object?>>
              value) =>
          value.isEmpty ? null : value.single),
    );
    return entry;
  }

  @override
  Stream<Entry> getBookmarked(TranslationMode translationMode,
      {required int startAt}) {
    super.getBookmarked(translationMode, startAt: startAt);
    return _getEntries(
      translationMode,
      rawSearchString: '',
      startAt: startAt,
      isBookmarkedOnly: true,
    );
  }

  @override
  Future<bool> setBookmark(TranslationMode translationMode,
      String urlEncodedHeadword, bool bookmark) async {
    final Database db = await _dbFuture;
    if (bookmark) {
      await db.insert(
        bookmarksTable(translationMode),
        {
          BOOKMARK_TAG: FAVORITES,
          URL_ENCODED_HEADWORD: urlEncodedHeadword,
        },
      );
    } else {
      await db.delete(
        bookmarksTable(translationMode),
        where: '$URL_ENCODED_HEADWORD = \'$urlEncodedHeadword\'',
      );
    }
    return super.setBookmark(translationMode, urlEncodedHeadword, bookmark);
  }

  Entry _rowToEntry(String headword, TranslationMode translationMode,
      Map<String, Object?>? snapshot) {
    if (snapshot == null) {
      final Entry notFound = EntryUtils.notFound(headword);
      super.setBookmark(
        translationMode,
        notFound.headword.urlEncodedHeadword,
        false,
      );
      return notFound;
    }
    assert(snapshot.containsKey(IS_FAVORITE));
    final Entry entry = Entry.fromBuffer(snapshot[ENTRY_BLOB] as List<int>);
    super.setBookmark(translationMode, entry.headword.urlEncodedHeadword,
        snapshot[IS_FAVORITE] == 1);
    return entry;
  }

  DialogueChapter _rowToDialogue(Map<String, Object?> snapshot) {
    return DialogueChapter.fromBuffer(snapshot[DIALOGUE_BLOB] as List<int>);
  }

  @override
  Stream<DialogueChapter> getDialogues({
    int? startAt,
  }) async* {
    final Database db = await _dbFuture;
    int offset = startAt ?? 0;
    while (true) {
      final String query = '''
    SELECT *
    FROM $DIALOGUES_TABLE
    ORDER BY $DIALOGUE_ID ASC
    LIMIT 20
    OFFSET $offset;
      ''';
      final List<Map<String, Object?>> snapshot = await db.rawQuery(query);
      if (snapshot.isEmpty) {
        return;
      }
      for (final DialogueChapter dialogue
          in snapshot.map((Map<String, Object?> snap) {
        return _rowToDialogue(snap);
      })) {
        yield dialogue;
        offset++;
      }
    }
  }

  Stream<Entry> _getEntries(
    TranslationMode translationMode, {
    required String rawSearchString,
    required int startAt,
    required bool isBookmarkedOnly,
  }) async* {
    final Database db = await _dbFuture;
    int offset = startAt;
    String searchString = rawSearchString;
    searchString = rawSearchString.withoutDiacriticalMarks;
    String orderByClause = ENTRY_ID;
    if (searchString.isNotEmpty) {
      orderByClause = '''
  ${_relevancyScore(searchString, HEADWORD)},
  ${_relevancyScore(searchString, HEADWORD_ABBREVIATIONS)},
  ${_relevancyScore(searchString, ALTERNATE_HEADWORDS)},
  ${_relevancyScore(searchString, IRREGULAR_INFLECTIONS)},
  ${_relevancyScore(searchString, HEADWORD + WITHOUT_OPTIONALS)},
  ${_relevancyScore(searchString, HEADWORD_ABBREVIATIONS + WITHOUT_OPTIONALS)},
  ${_relevancyScore(searchString, ALTERNATE_HEADWORDS + WITHOUT_OPTIONALS)},
  ${_relevancyScore(searchString, IRREGULAR_INFLECTIONS + WITHOUT_OPTIONALS)},
  headword''';
    }
    String whereClause = '''$IS_FAVORITE''';
    if (!isBookmarkedOnly)
      whereClause = '''
  (${_relevancyScore(searchString, HEADWORD)} != $NO_MATCH
   OR ${_relevancyScore(searchString, HEADWORD_ABBREVIATIONS)} != $NO_MATCH
   OR ${_relevancyScore(searchString, ALTERNATE_HEADWORDS)} != $NO_MATCH
   OR ${_relevancyScore(searchString, IRREGULAR_INFLECTIONS)} != $NO_MATCH
   OR ${_relevancyScore(searchString, HEADWORD + WITHOUT_OPTIONALS)} != $NO_MATCH
   OR ${_relevancyScore(searchString, HEADWORD_ABBREVIATIONS + WITHOUT_OPTIONALS)} != $NO_MATCH
   OR ${_relevancyScore(searchString, ALTERNATE_HEADWORDS + WITHOUT_OPTIONALS)} != $NO_MATCH
   OR ${_relevancyScore(searchString, IRREGULAR_INFLECTIONS + WITHOUT_OPTIONALS)} != $NO_MATCH)''';
    while (true) {
      final String query = '''SELECT *,
       EXISTS(SELECT $BOOKMARK_TAG, $URL_ENCODED_HEADWORD
              FROM ${bookmarksTable(translationMode)}
              WHERE ${entryTable(translationMode)}.$URL_ENCODED_HEADWORD = 
                ${bookmarksTable(translationMode)}.$URL_ENCODED_HEADWORD) AS $IS_FAVORITE
FROM ${entryTable(translationMode)}
WHERE $whereClause
ORDER BY $orderByClause
LIMIT 20
OFFSET $offset;''';
      final List<Map<String, Object?>> snapshot = await db.rawQuery(query);
      if (snapshot.isEmpty) {
        return;
      }
      for (final Entry entry in snapshot.map((Map<String, Object?> snap) {
        return _rowToEntry('', translationMode, snap);
      })) {
        yield entry;
        offset++;
      }
    }
  }

  @override
  Future<void> dispose() async {
    final Database db = await _dbFuture;
    return db.close();
  }

  Future<String> _getDatabasePath() async {
    if (Platform.isWindows) {
      return File('~\\Documents').absolute.path;
    }
    return getDatabasesPath();
  }

  Future<Database> _getDatabase() async {
    // Check if the database exists
    final bool exists = await databaseExists(_path);
    if (!exists) {
      // Make sure the parent directory exists
      try {
        await Directory(dirname(_path)).create(recursive: true);
      } catch (e) {
        print(e);
      }

      // Copy from asset.
      await _copyDb('${DICTIONARY_DB}V${_version.versionString}.db', _path);
      if (!await databaseExists(_bookmarksPath)) {
        await _copyDb('$BOOKMARKS_DB.db', _bookmarksPath);
      }
    } else {
      print('Opening existing database');
    }
    // open the database
    return _openDatabase();
  }

  Future<void> _copyDb(String assetName, String targetPath) async {
    print('Creating new copy from asset: $assetName');
    //Don't use join, it breaks on Windows.
    final ByteData data = await rootBundle.load('assets/$assetName');
    final List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Write and flush the bytes written
    await File(targetPath).writeAsBytes(bytes, flush: true);
  }

  Future<Database> _openDatabase() async {
    late Database db;
    if (Platform.isWindows) {
      db = await databaseFactoryFfi.openDatabase(_path);
    } else {
      db = await databaseFactory.openDatabase(_path);
    }
    db = await databaseFactory.openDatabase(_path);
    await db.execute('''ATTACH DATABASE '$_bookmarksPath' AS $BOOKMARKS_DB''');
    return db;
  }
}
