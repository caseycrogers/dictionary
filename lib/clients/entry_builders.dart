import 'dart:convert';
import 'dart:io';

import 'package:rogers_dictionary/clients/database_constants.dart';
import 'package:rogers_dictionary/i18n_base.dart' as i18n;
import 'package:rogers_dictionary/protobufs/database_version.pb.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';

typedef Headword = Entry_Headword;
typedef Translation = Entry_Translation;

extension VersionUtils on DatabaseVersion {
  static DatabaseVersion fromDisk(File file) {
    return fromString(file.readAsStringSync());
  }

  static DatabaseVersion fromString(String jsonString) {
    return DatabaseVersion()
      ..mergeFromProto3Json(jsonDecode(jsonString))
      ..freeze();
  }

  void write(File file) {
    file.writeAsStringSync(jsonEncode(toProto3Json()));
  }

  DatabaseVersion incremented() => DatabaseVersion(
        major: major,
        minor: minor,
        patch: patch + 1,
      )..freeze();

  String get versionString => '$major.$minor.$patch';
}

extension EntryUtils on Entry {
  List<Headword> get allHeadwords => [headword, ...alternateHeadwords];

  bool get isNotFound =>
      headword.urlEncodedHeadword.startsWith('Invalid headword ');

  static String urlDecode(String urlEncodedHeadword) {
    return Uri.decodeComponent(
        (urlEncodedHeadword.split('_')..removeAt(0)).join(''));
  }

  static String urlEncode(String headword) {
    return Uri.encodeComponent(headword);
  }

  static Entry notFound(String headword) {
    return Entry(
      entryId: 404,
      headword: Headword(
        isAlternate: false,
        headwordText: 'Invalid headword \'$headword\'',
      ),
      translations: <Translation>[
        Translation(
          partOfSpeech: '',
          content:
              'Please use the help button (upper right) to report this bug!',
        ),
      ],
    );
  }

  static final Map<String, i18n.Message> _partOfSpeechAbbreviationMap = {
    'adj': i18n.adjective,
    'adv': i18n.adverb,
    'conj': i18n.conjunction,
    'deg': i18n.degree,
    'f': i18n.feminineNoun,
    'fpl': i18n.femininePluralNoun,
    'f(pl)': i18n.femininePluralNounParen,
    'inf': i18n.infinitive,
    'interj': i18n.interjection,
    'm': i18n.masculineNoun,
    'mf': i18n.masculineFeminineNoun,
    'mpl': i18n.masculinePluralNoun,
    'm(pl)': i18n.masculinePluralNounParen,
    'n': i18n.noun,
    'npl': i18n.pluralNoun,
    'n(pl)': i18n.pluralNounParen,
    'pref': i18n.prefix,
    'prep': i18n.preposition,
    'v': i18n.verb,
    'vi': i18n.intransitiveVerb,
    'vr': i18n.reflexiveVerb,
    'vt': i18n.transitiveVerb,
    '-': i18n.phrase,
    '': i18n.blank,
    'adjphrase': i18n.blank,
    'advphrase': i18n.adverbPhrase,
    'degphrase': i18n.degreePhrase,
    'nphrase': i18n.nounPhrase,
    'nplphrase': i18n.pluralNounPhrase,
    'prepphrase': i18n.prepositionPhrase,
    'vphrase': i18n.verbPhrase,
    'fphrase': i18n.feminineNounPhrase,
    'fplphrase': i18n.femininePluralNounPhrase,
    'mfphrase': i18n.masculineFeminineNounPhrase,
    'mphrase': i18n.masculineNounPhrase,
    'mplphrase': i18n.masculinePluralNounPhrase,
    'm(pl)phrase': i18n.masculinePluralNounPhraseParen,
  };

  static String longPartOfSpeech(
    String partOfSpeech,
    bool isSpanish,
  ) {
    return partOfSpeech
        .replaceAll(' ', '')
        .splitMapJoin(
          RegExp('[&,]'),
          onNonMatch: (String partOfSpeechComponent) =>
              _partOfSpeechAbbreviationMap[partOfSpeechComponent]
                  ?.getFor(isSpanish) ??
              '$partOfSpeechComponent*',
          onMatch: (Match separator) {
            //  == '&' ? ' and ' : ', ',
            switch (separator.group(0)) {
              case '&':
                return ' and ';
              case ',':
                return ', ';
              default:
                return separator.group(0)!;
            }
          },
        );
  }
}

extension HeadwordUtils on Headword {
  String get urlEncodedHeadword => EntryUtils.urlEncode(headwordText);
}

extension TranslationUtils on Translation {
  String get getOppositeHeadword =>
      oppositeHeadword == OPPOSITE_HEADWORD_SENTINEL
          ? content
          : oppositeHeadword;

  String getLocalizedPartOfSpeech(bool isSpanish) {
    return partOfSpeech.replaceAll('phrase', 'frase');
  }
}

class EntryBuilder {
  late Headword _headword;
  late int _entryId;
  List<Headword>? _alternateHeadwords;
  List<String>? _related;

  final List<Translation> _translations = <Translation>[];

  EntryBuilder headword(
      String headwordText, String abbreviation, String parentheticalQualifier) {
    _headword = Headword(
      isAlternate: false,
      headwordText: headwordText,
      abbreviation: abbreviation,
      namingStandard: null,
      parentheticalQualifier: parentheticalQualifier,
    );
    return this;
  }

  EntryBuilder entryId(int entryId) {
    _entryId = entryId;
    return this;
  }

  EntryBuilder addRelated(List<String> related) {
    if (related.isNotEmpty) {
      _related = (_related ?? <String>[])..addAll(related);
    }
    return this;
  }

  EntryBuilder addAlternateHeadword({
    required String headwordText,
    required String abbreviation,
    required String namingStandard,
    required String parentheticalQualifier,
  }) {
    assert(
        headwordText != '',
        'You must specify a non-empty alternate headword. '
        'Headword: ${_headword.headwordText}. Line: ${_entryId + 2}');
    _alternateHeadwords = (_alternateHeadwords ?? <Headword>[])
      ..add(
        Headword(
          isAlternate: true,
          headwordText: headwordText,
          abbreviation: abbreviation,
          namingStandard: namingStandard,
          parentheticalQualifier: parentheticalQualifier,
        ),
      );
    return this;
  }

  EntryBuilder addTranslation({
    required String partOfSpeech,
    required List<String> irregularInflections,
    required String dominantHeadwordParentheticalQualifier,
    required String translation,
    required String genderAndPlural,
    required String namingStandard,
    required String abbreviation,
    required String parentheticalQualifier,
    required List<String> examplePhrases,
    required String editorialNote,
    required String oppositeHeadword,
  }) {
    assert(
        translation != '',
        'You must specify a non-empty translation. '
        'Headword: ${_headword.headwordText} at line $_entryId');
    _translations.add(
      Translation(
        partOfSpeech: partOfSpeech,
        irregularInflections: irregularInflections,
        dominantHeadwordParentheticalQualifier:
            dominantHeadwordParentheticalQualifier,
        content: translation,
        genderAndPlural: genderAndPlural,
        namingStandard: namingStandard,
        abbreviation: abbreviation,
        parentheticalQualifier: parentheticalQualifier,
        examplePhrases: examplePhrases,
        editorialNote: editorialNote,
        oppositeHeadword: oppositeHeadword,
      ),
    );
    return this;
  }

  Entry build() {
    assert(_translations.isNotEmpty,
        'You must specify one or more translations. Line ${_entryId + 2}.');
    return Entry(
      entryId: _entryId,
      headword: _headword,
      related: _related,
      alternateHeadwords: _alternateHeadwords,
      translations: _translations,
    );
  }
}
