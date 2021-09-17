import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:df/df.dart';
import 'package:path/path.dart';

import 'package:rogers_dictionary/clients/database_constants.dart';
import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/models/translation_mode.dart';
import 'package:rogers_dictionary/protobufs/database_version.pb.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'package:rogers_dictionary/util/collection_utils.dart';
import 'package:rogers_dictionary/util/overflow_markdown_base.dart';
import 'package:rogers_dictionary/util/string_utils.dart';

import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const WARNING = '(WARN):';
const ERROR = '(ERROR):';

Future<void> uploadEntries(bool debug, bool verbose, bool isSpanish) async {
  final String csvPath = join(
    'lib',
    'scripts',
    'entry_database-'
        '${isSpanish ? SPANISH : ENGLISH}.csv',
  );
  final String versionPath = join('assets', 'database_version.json');
  final DatabaseVersion version = VersionUtils.fromDisk(File(versionPath));
  print('Uploading version ${version.versionString} from $csvPath.');
  final DataFrame df = await DataFrame.fromCsv(csvPath);

  final Iterable<Map<String, String>> rows =
      df.rows.map((row) => row.map(_parseCell));
  EntryBuilder? builder;
  String? partOfSpeech;
  String? dominantHeadwordParentheticalQualifier;
  var i = 0;
  final Map<String, EntryBuilder> entryBuilders = {};

  while (rows.elementAt(i)[HEADWORD] != 'START') {
    if (i == 100) {
      print('$ERROR Reached row ${i + 2} without finding the start of entries, '
          'cancelling.');
      return;
    }
    i++;
  }
  i++;
  while (i < rows.length && i < 100) {
    if ((i + 2) % 500 == 0) {
      print('${i + 2}/${rows.length + 2} complete!');
    }
    Map<String, String> row = rows.elementAt(i);
    if (row.entries
        .where((e) => e.key.isNotEmpty)
        .every((e) => e.value.isEmpty)) {
      print('$WARNING Skipping empty line at ${i + 2}');
      i += 1;
      continue;
    }
    row.forEach((key, str) {
      if (key != EDITORIAL_NOTE && (str.contains('\n') || str.contains('\r')))
        print('$WARNING field $key at row ${i + 2} contains a line break.'
            ' Field:\n$str');
    });
    if (row[HEADWORD]!.isNotEmpty) {
      if ((row[PART_OF_SPEECH]!.isEmpty && row[RUN_ON_PARENTS]!.isEmpty) ||
          row[TRANSLATION]!.isEmpty) {
        print('$ERROR Invalid empty cells for \'${row[HEADWORD]}\' at row '
            '${i + 2}, skipping.');
        i += 1;
        row = rows.elementAt(i);
        while (row[HEADWORD]!.isEmpty) {
          i += 1;
          row = rows.elementAt(i);
        }
        continue;
      }
      var parents = <String>[];
      if (row[RUN_ON_PARENTS]!.isNotEmpty) {
        parents = row[RUN_ON_PARENTS]!.split('|');
        for (final String parent in parents) {
          if (parent == parents[0] && parent.isEmpty) {
            continue;
          }
          entryBuilders[parent]?.addRelated([row[HEADWORD]!]) ??
              print('$WARNING Missing run on parent \'$parent\' for entry '
                  '\'${row[HEADWORD]}\' at line ${i + 2}');
        }
      }
      builder = EntryBuilder()
          .entryId(i + 2)
          .headword(
              row[HEADWORD]!,
              _split(row[HEADWORD_ABBREVIATIONS]!).get(0, orElse: ''),
              _split(row[HEADWORD_PARENTHETICAL_QUALIFIERS]!)
                  .get(0, orElse: ''))
          .addRelated(parents);
      _split(row[ALTERNATE_HEADWORDS]!)
          .asMap()
          .forEach((i, alternateHeadwordText) {
        // Start from i + 1 because the first slow was taken by the headword.
        final int index = i + 1;
        builder!.addAlternateHeadword(
          headwordText: alternateHeadwordText,
          abbreviation:
              _split(row[HEADWORD_ABBREVIATIONS]!).get(index, orElse: ''),
          namingStandard: _split(row[ALTERNATE_HEADWORD_NAMING_STANDARDS]!)
              .get(i, orElse: ''),
          parentheticalQualifier:
              _split(row[HEADWORD_PARENTHETICAL_QUALIFIERS]!)
                  .get(index, orElse: ''),
        );
      });
      if (entryBuilders.keys.contains(row[HEADWORD]))
        print('$WARNING Duplicate headword ${row[HEADWORD]} at line ${i + 2}');
      entryBuilders[row[HEADWORD]!] = builder;
      partOfSpeech = '';
      dominantHeadwordParentheticalQualifier = '';
    }
    if (row[PART_OF_SPEECH]!.isNotEmpty) {
      partOfSpeech = row[PART_OF_SPEECH]!;
      // Reset the qualifier
      dominantHeadwordParentheticalQualifier = '';
      if (EntryUtils.longPartOfSpeech(partOfSpeech, false).contains('*'))
        print('$WARNING Unrecognized part of speech $partOfSpeech for headword '
            '${row[HEADWORD]} at line ${i + 2}');
    }
    if (row[DOMINANT_HEADWORD_PARENTHETICAL_QUALIFIER]!.isNotEmpty)
      dominantHeadwordParentheticalQualifier =
          row[DOMINANT_HEADWORD_PARENTHETICAL_QUALIFIER]!;
    builder!.addTranslation(
      partOfSpeech: partOfSpeech!,
      irregularInflections: _split(row[IRREGULAR_INFLECTIONS]!, pattern: ';'),
      dominantHeadwordParentheticalQualifier:
          dominantHeadwordParentheticalQualifier!,
      translation: row[TRANSLATION]!,
      genderAndPlural: row[GENDER_AND_PLURAL]!,
      namingStandard: row[TRANSLATION_NAMING_STANDARD]!,
      abbreviation: row[TRANSLATION_ABBREVIATION]!,
      parentheticalQualifier: row[TRANSLATION_PARENTHETICAL_QUALIFIER]!,
      examplePhrases: _split(row[EXAMPLE_PHRASES]!),
      editorialNote: row[EDITORIAL_NOTE]!,
      oppositeHeadword: row[OPPOSITE_HEADWORD]!,
    );
    i++;
  }
  if (!debug) {
    version.write(File(versionPath));
  }
  print('Finished writing ${version.versionString} with $i rows.');
  assert(builder != null, 'Did not generate any entries!');
  return _uploadSqlFlite(
    version,
    isSpanish ? TranslationMode.Spanish : TranslationMode.English,
    entryBuilders.values.map((b) => b.build()).toList(),
    debug,
    verbose,
  );
}

Future<void> _uploadSqlFlite(
  DatabaseVersion version,
  TranslationMode mode,
  List<Entry> entries,
  bool debug,
  bool verbose,
) async {
  final path = join(
    Directory.current.path,
    'assets',
    '${DICTIONARY_DB}V${version.versionString}.db',
  );
  final bookmarksPath = join(
    Directory.current.path,
    'assets',
    '$BOOKMARKS_DB.db',
  );
  print('Writing to: $path.');
  sqfliteFfiInit();
  final Database db = await databaseFactoryFfi.openDatabase(path);
  final Database bookmarksDb =
      await databaseFactoryFfi.openDatabase(bookmarksPath);
  final Batch batch = db.batch();
  if (!debug) {
    await wipeTable(db, entryTable(mode));
    await wipeTable(bookmarksDb, bookmarksTable(mode));
    await createEntryTable(db, entryTable(mode));
    await createBookmarksTable(bookmarksDb, bookmarksTable(mode));
  }

  for (final Entry entry in entries) {
    final Map<String, Object> entryRecord = {
      URL_ENCODED_HEADWORD: entry.headword.urlEncodedHeadword,
      ENTRY_ID: entry.entryId,
      HEADWORD: entry.headword.headwordText.searchable,
      RUN_ON_PARENTS: entry.related.join(' | ').searchable,
      HEADWORD_ABBREVIATIONS:
          entry.allHeadwords.map((h) => h.abbreviation).join(' | ').searchable,
      ALTERNATE_HEADWORDS: entry.alternateHeadwords
          .map((alt) => alt.headwordText)
          .join(' | ')
          .searchable,
      IRREGULAR_INFLECTIONS: entry.translations.first.irregularInflections
          // Non-content phrases are italicized in irregular inflections
          .expand((s) => MarkdownBase(s).strip(italics: true))
          .where((s) => s.isNotEmpty)
          .join(' | ')
          .searchable,
      HEADWORD + WITHOUT_OPTIONALS:
          entry.headword.headwordText.withoutOptionals.searchable,
      RUN_ON_PARENTS + WITHOUT_OPTIONALS:
          entry.related.map((p) => p.withoutOptionals).join(' | ').searchable,
      HEADWORD_ABBREVIATIONS + WITHOUT_OPTIONALS: entry.allHeadwords
          .map((h) => h.abbreviation.withoutOptionals)
          .join(' | ')
          .searchable,
      ALTERNATE_HEADWORDS + WITHOUT_OPTIONALS: entry.alternateHeadwords
          .map((alt) => alt.headwordText.withoutOptionals)
          .join(' | ')
          .searchable,
      IRREGULAR_INFLECTIONS + WITHOUT_OPTIONALS: entry
          .translations.first.irregularInflections
          .expand((s) => MarkdownBase(s).strip(italics: true))
          .map((s) => s.withoutOptionals)
          .where((s) => s.isNotEmpty)
          .join(' | ')
          .searchable,
      ENTRY_BLOB: entry.writeToBuffer(),
    };
    if (verbose) {
      print(entryRecord.map((key, value) =>
          MapEntry(key, key == ENTRY_BLOB ? entry.toProto3Json() : value)));
      print('');
    }
    batch.insert(entryTable(mode), entryRecord);
  }
  if (debug) {
    return;
  }
  return batch.commit().then((_) => null);
}

Future<void> wipeTable(Database db, String tableName) async {
  try {
    await db.execute('''DROP TABLE $tableName''');
  } on Exception catch (e) {
    print(e.toString());
  }
  return;
}

Future<void> createEntryTable(Database db, String tableName) async {
  print('Creating table ${db.path}.$tableName.');
  await db.execute('''CREATE TABLE $tableName(
    $URL_ENCODED_HEADWORD STRING NOT NULL PRIMARY KEY,
    $ENTRY_ID INTEGER NOT NULL,
    $HEADWORD STRING NOT NULL,
    $RUN_ON_PARENTS STRING,
    $HEADWORD_ABBREVIATIONS STRING,
    $ALTERNATE_HEADWORDS String,
    $HEADWORD$WITHOUT_OPTIONALS STRING NOT NULL,
    $RUN_ON_PARENTS$WITHOUT_OPTIONALS STRING,
    $HEADWORD_ABBREVIATIONS$WITHOUT_OPTIONALS STRING,
    $ALTERNATE_HEADWORDS$WITHOUT_OPTIONALS String,
    $IRREGULAR_INFLECTIONS String,
    $IRREGULAR_INFLECTIONS$WITHOUT_OPTIONALS String,
    $ENTRY_BLOB BLOB NOT NULL
  )''');
  return;
}

Future<void> createBookmarksTable(Database db, String tableName) async {
  print('Creating table $tableName in ${db.path}.');
  await db.execute('''CREATE TABLE $tableName(
    $BOOKMARK_TAG STRING NOT NULL,
    $URL_ENCODED_HEADWORD STRING NOT NULL
  )''');
  return;
}

MapEntry<String, String> _parseCell(String key, dynamic value) {
  if (!(value is String)) {
    value = '';
  }
  final str = value;
  return MapEntry(
      key.trim(),
      str
          .trim()
          .replaceAll(' | ', '|')
          .replaceAll('| ', '|')
          .replaceAll(' |', '|'));
}

List<String> _split(String pluralValue, {String? pattern}) {
  return pluralValue.isEmpty ? [] : pluralValue.split(pattern ?? '|');
}

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('debug', abbr: 'd', defaultsTo: false)
    ..addFlag('verbose', abbr: 'v', defaultsTo: false)
    ..addFlag('spanish', abbr: 's', defaultsTo: false);
  final argResults = parser.parse(arguments);

  await uploadEntries(argResults['debug'] as bool,
      argResults['verbose'] as bool, argResults['spanish'] as bool);
  print('done?');
}
