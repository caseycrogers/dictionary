// Project imports:
import 'package:rogers_dictionary/models/translation_mode.dart';

const WARNING = 'WARN:';
const ERROR = 'ERROR:';

const String ENGLISH = 'english';
const String SPANISH = 'spanish';
const String DICTIONARY_DB = 'dictionary';
const String VERSION_FILE = 'database_version.json';

const String BOOKMARKS_DB = 'bookmarks';

const String SQL_SCHEMA_TABLE = 'sqlite_master';

// Entry column names.
const String UID = 'uid';
const String HEADWORD = 'headword';
const String URL_ENCODED_HEADWORD = 'headword';
const String ORDER_ID = 'order_id';
const String ENTRY_BLOB = 'entry_blob';

// Bookmarks column names.
const String FAVORITES = 'favorites';
const String BOOKMARK_TAG = 'tag';

const String IS_FAVORITE = 'is_favorite';

const String RELATED_TERMS_TRANSITIVE = 'related_terms_transitive';
const String RELATED_TERMS_INTRANSITIVE = 'related_terms_intransitive';
const String RUN_ON_TEXT = 'run_on_text';
const String HEADWORD_ABBREVIATIONS = 'headword_abbreviations';
const String ALTERNATE_HEADWORDS = 'alternate_headwords';
const String ALTERNATE_HEADWORD_GENDERS = 'alternate_headword_genders';
const String ALTERNATE_HEADWORD_NAMING_STANDARDS =
    'alternate_headword_naming_standards';
const String IRREGULAR_INFLECTIONS = 'irregular_inflections';
const String PART_OF_SPEECH = 'part_of_speech';
const String HEADWORD_RESTRICTIVE_LABEL = 'headword_restrictive_label';

const String HEADWORD_PARENTHETICAL_QUALIFIERS =
    'headword_parenthetical_qualifiers';
const String DOMINANT_HEADWORD_PARENTHETICAL_QUALIFIER =
    'dominant_headword_parenthetical_qualifier';
const String TRANSLATION = 'translation';
const String PRONUNCIATION_OVERRIDE = 'pronunciation_override';
const String SHOULD_BE_KEY_PHRASE = 'should_be_key_phrase';
const String GENDER_AND_PLURAL = 'gender_and_plural';
const String TRANSLATION_NAMING_STANDARD = 'translation_naming_standard';
const String TRANSLATION_ABBREVIATION = 'translation_abbreviation';
const String TRANSLATION_PARENTHETICAL_QUALIFIER =
    'translation_parenthetical_qualifier';
const String DISAMBIGUATION = 'disambiguation';
const String EXAMPLE_PHRASES = 'example_phrases';
const String EDITORIAL_NOTE = 'editorial_note';
const String OPPOSITE_HEADWORD = 'opposite_headword';

// Dialogue constants.
const String DIALOGUES_TABLE = 'dialogues';
const String DIALOGUE_BLOB = 'dialogue_blob';

const String DIALOGUE_ID = 'dialogue_id';
const String ENGLISH_CHAPTER = 'english_chapter';
const String SPANISH_CHAPTER = 'spanish_chapter';
const String ENGLISH_SUBCHAPTER = 'english_subchapter';
const String SPANISH_SUBCHAPTER = 'spanish_subchapter';
const String ENGLISH_CONTENT = 'english_content';
const String SPANISH_CONTENT = 'spanish_content';

// Misc.
const String WITHOUT_OPTIONALS = '_without_optionals';
// Used to indicate that an opposite headword is just the translation content.
const String OPPOSITE_HEADWORD_SENTINEL = '1';

// Shared preferences.

const String feedbackEmail = 'feedback_email';

String entryTable(TranslationMode mode) {
  if (mode == TranslationMode.English) {
    return ENGLISH;
  }
  return SPANISH;
}

String bookmarksTable(TranslationMode mode) {
  if (mode == TranslationMode.English) {
    return '${ENGLISH}_$BOOKMARKS_DB';
  }
  return '${SPANISH}_$BOOKMARKS_DB';
}
