import 'package:rogers_dictionary/util/overflow_markdown_base.dart';

import 'collection_utils.dart';

extension NotShittyString on String {
  static const diacritics =
      'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  static const nonDiacritics =
      'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

  static const List<String> symbols = [
    '(',
    ')',
    '*',
    '`',
  ];

  String get withoutDiacriticalMarks => splitMapJoin('',
      onNonMatch: (char) => char.isNotEmpty && diacritics.contains(char)
          ? nonDiacritics[diacritics.indexOf(char)]
          : char);

  String get searchable => toLowerCase().withoutDiacriticalMarks.splitMapJoin(
        '',
        onNonMatch: (char) => symbols.contains(char) ? '' : char,
      );

  String get withoutOptionals => replaceAll(RegExp(r'\(.*?\) ?'), '').trim();

  String get withoutHyphenateds => replaceAll(RegExp(r' -.[^ ]+'), '').trim();

  String get withoutGenderIndicators =>
      replaceAll(RegExp(r' \*[mf]+\*'), '').trim();

  String get pronounceable => withoutHyphenateds.withoutGenderIndicators;

  String? get emptyToNull => isNotEmpty ? this : null;

  List<String> get splitItalicized => MarkdownBase(this).strip(italics: true);

  String get capitalizeFirst => split('')
      .asMap()
      .mapDown((i, c) => i == 0 ? c.toUpperCase() : c)
      .join('');

  String get enumString => split('.').last;

  String get feminized => splitMapJoin(
        ' ',
        onNonMatch: (word) => word.replaceAll(RegExp('o\$'), 'a'),
      );

  String spanishAdjectiveReorder(String nounToReorder) => replaceAllMapped(
        RegExp('(.*) $nounToReorder'),
        (match) => '$nounToReorder ${match.group(1)}',
      );

  String truncated(int maxLength) =>
      length > maxLength - 3 ? '${split('').take(maxLength).join()}...' : this;
}
