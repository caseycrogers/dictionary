import 'dart:async';
import 'dart:io';

import 'package:rogers_dictionary/clients/database_constants.dart';
import 'package:rogers_dictionary/clients/dialogue_builders.dart';
import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/protobufs/database_version.pb.dart';
import 'package:rogers_dictionary/protobufs/dialogues.pb.dart';

import 'package:args/args.dart';
import 'package:df/df.dart';
import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const WARNING = '(WARN):';
const ERROR = '(ERROR):';

Future<void> uploadDialogues(bool debug, bool verbose) async {
  final String filePath = join(
    'lib',
    'scripts',
    'dialogue_database.csv',
  );
  print('Uploading: $filePath.');
  final DataFrame df = await DataFrame.fromCsv(filePath);

  final Iterable<Map<String, String>> rows =
      df.rows.map((row) => row.map(_parseCell));
  String? englishSubChapter;
  String? spanishSubChapter;
  DialogueChapterBuilder? builder;

  final List<DialogueChapterBuilder> builders = [];
  var i = 0;

  while (rows.elementAt(i)[ENGLISH_CHAPTER] != 'START') {
    if (i == 100) {
      print('$ERROR Reached row ${i + 2} without finding the start of '
          'dialogues, cancelling.');
      return;
    }
    i++;
  }
  i++;
  var builderCount = 0;
  while (i < rows.length) {
    if ((i + 2) % 500 == 0) {
      print('${i + 2}/${rows.length + 2} complete!');
    }
    Map<String, String> row = rows.elementAt(i);
    if (row.values.every((e) => e.isEmpty)) {
      print('$WARNING Skipping empty line at ${i + 2}');
      i += 1;
      continue;
    }
    if (row[ENGLISH_CHAPTER]!.isNotEmpty) {
      if (row[SPANISH_CHAPTER]!.isEmpty) {
        print('$ERROR Invalid empty cells for \'${row[ENGLISH_CHAPTER]}\' at '
            'row ${i + 2}, skipping.');
        i += 1;
        row = rows.elementAt(i);
        while (row[ENGLISH_CHAPTER]!.isEmpty && i + 1 < rows.length) {
          i += 1;
          row = rows.elementAt(i);
        }
        continue;
      }
      builder = DialogueChapterBuilder(
        chapterId: builderCount++,
        englishTitle: row[ENGLISH_CHAPTER]!,
        spanishTitle: row[SPANISH_CHAPTER]!,
      );
      builders.add(builder);
      englishSubChapter = row[ENGLISH_SUBCHAPTER]!;
      spanishSubChapter = row[SPANISH_SUBCHAPTER]!;
    } else {
      if (row[ENGLISH_SUBCHAPTER]!.isNotEmpty) {
        englishSubChapter = row[ENGLISH_SUBCHAPTER]!;
        spanishSubChapter = row[SPANISH_SUBCHAPTER]!;
      }
    }
    builder!.addDialogue(
      englishSubChapter!,
      spanishSubChapter!,
      row[ENGLISH_CONTENT]!,
      row[SPANISH_CONTENT]!,
    );
    i++;
  }
  assert(builders.isNotEmpty, 'Did not generate any dialogues!');
  return _uploadSqlFlite(
    builders.map((b) => b.build()).toList(),
    debug,
    verbose,
  );
}

Future<void> _uploadSqlFlite(
  List<DialogueChapter> dialogueChapters,
  bool debug,
  bool verbose,
) async {
  final String versionPath = join('assets', 'database_version.json');
  final DatabaseVersion version = VersionUtils.fromDisk(
    File(versionPath),
  );
  final path = join(Directory.current.path, 'assets',
      '${DICTIONARY_DB}V${version.versionString}.db');
  print('Writing to: $path.');
  sqfliteFfiInit();
  final Database db = await databaseFactoryFfi.openDatabase(path);
  try {
    await db.execute('''DROP TABLE $DIALOGUES_TABLE''');
  } on Exception catch (e) {
    print(e.toString());
  }
  await db.execute('''CREATE TABLE $DIALOGUES_TABLE(
    $DIALOGUE_ID INTEGER NOT NULL  PRIMARY KEY,
    $DIALOGUE_BLOB BLOB NOT NULL
  )''');
  final Batch batch = db.batch();
  for (final chapter in dialogueChapters) {
    final Map<String, Object> dialogueRecord = {
      DIALOGUE_ID: chapter.chapterId,
      DIALOGUE_BLOB: chapter.writeToBuffer(),
    };
    if (verbose) {
      print(chapter.toProto3Json());
    }
    batch.insert(DIALOGUES_TABLE, dialogueRecord);
  }
  return batch.commit().then((_) => null);
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

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag('debug', abbr: 'd', defaultsTo: false)
    ..addFlag('verbose', abbr: 'v', defaultsTo: false);
  final ArgResults argResults = parser.parse(arguments);

  uploadDialogues(argResults['debug'] as bool, argResults['verbose'] as bool)
      .then((_) => print('done?'));
}
