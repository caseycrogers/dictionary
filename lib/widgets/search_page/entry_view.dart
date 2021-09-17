import 'package:collection/collection.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/pages/page_header.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/util/delayed.dart';
import 'package:rogers_dictionary/util/overflow_markdown.dart';
import 'package:rogers_dictionary/util/text_utils.dart';

class EntryView extends StatelessWidget {
  EntryView._instance(this._entry, this._preview) {
    if (_entry.isNotFound) {
      FirebaseCrashlytics.instance.recordError(
        'Invalid headword ${_entry.headword}',
        null,
      );
    }
  }

  final Entry _entry;
  final bool _preview;

  static Widget asPage(SelectedEntry selectedEntry) => Builder(
        key: ValueKey(selectedEntry.urlEncodedHeadword),
        builder: (context) {
          return FutureBuilder(
            future: selectedEntry.entry,
            builder: (context, AsyncSnapshot<Entry> snap) {
              if (!snap.hasData || snap.data == null)
                // Only display if loading is slow.
                return Delayed(
                  initialChild: Container(),
                  child: Container(),
                  delay: const Duration(milliseconds: 50),
                );
              final Entry entry = snap.data!;
              return PageHeader(
                header: headwordLine(
                  context,
                  entry,
                  false,
                  SearchModel.of(context).searchString,
                ),
                child: EntryView._instance(entry, false),
              );
            },
          );
        },
      );

  static Widget asPreview(Entry entry) => EntryView._instance(entry, true);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_preview)
          headwordLine(
            context,
            _entry,
            _preview,
            SearchModel.of(context).searchString,
          ),
        if (!_preview) const SizedBox(height: kPad),
        _buildTable(context),
        if (!_preview) _buildEditorialNotes(context),
        if (!_preview) _buildRelated(context),
      ],
    );
  }

  Widget _buildRelated(BuildContext context) {
    if (_entry.related.isEmpty) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: kSectionSpacer),
        bold1Text(context, i18n.related.get(context)),
        const Divider(),
        ..._entry.related.where((r) => r.isNotEmpty).map(
              (headword) => TextButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(EdgeInsets.zero),
                  minimumSize: MaterialStateProperty.all(Size.zero),
                  visualDensity: VisualDensity.compact,
                ),
                child: OverflowMarkdown(
                  headword,
                  defaultStyle: Theme.of(context)
                      .textTheme
                      .bodyText2!
                      .copyWith(color: Colors.blue),
                ),
                onPressed: () {
                  DictionaryModel.of(context).onHeadwordSelected(
                    context,
                    EntryUtils.urlEncode(headword),
                    referrer: SelectedEntryReferrer.relatedHeadword,
                  );
                },
              ),
            ),
      ],
    );
  }

  Widget _buildEditorialNotes(BuildContext context) {
    final Iterable<Widget> notes = _entry.translations
        .where((t) => t.editorialNote.isNotEmpty)
        .map((t) => editorialText(context, t.editorialNote));
    if (notes.isEmpty) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: kSectionSpacer),
        bold1Text(context, i18n.editorialNotes.get(context)),
        const Divider(),
        ...notes,
      ],
    );
  }

  Widget _buildTable(BuildContext context) {
    return Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
        },
        defaultVerticalAlignment: _preview
            ? TableCellVerticalAlignment.middle
            : TableCellVerticalAlignment.top,
        children: _buildTranslations(context));
  }

  // Return a list of TableRows corresponding to each part of speech.
  List<TableRow> _buildTranslations(
    BuildContext context,
  ) {
    return _entry.translations
        .groupListsBy((t) => t.partOfSpeech)
        .values
        .map((translations) {
      final partOfSpeech = translations.first.partOfSpeech;
      final inflections = translations.first.irregularInflections;
      return _buildPartOfSpeechTableRow(
        context: context,
        partOfSpeech: partOfSpeech,
        inflections: inflections,
        translations: translations,
      );
    }).toList();
  }

  TableRow _buildPartOfSpeechTableRow({
    required BuildContext context,
    required String partOfSpeech,
    required List<String> inflections,
    required List<Translation> translations,
  }) {
    String parenthetical = '';
    final hasParenthetical = translations
        .any((t) => t.dominantHeadwordParentheticalQualifier.isNotEmpty);
    if (_preview)
      return TableRow(
        children: [
          Container(
            padding: translations.first != _entry.translations.first
                ? const EdgeInsets.only(top: kPad / 2)
                : null,
            child: partOfSpeechText(context, partOfSpeech, _preview),
            alignment: Alignment.topRight,
          ),
          Container(
            alignment: Alignment.topLeft,
            child: previewTranslationLine(
              context,
              translations,
            ),
          ),
        ],
      );
    return TableRow(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            partOfSpeechText(context, partOfSpeech, _preview),
            irregularInflectionsTable(context, inflections),
            Indent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: translations.map((t) {
                  final bool parentheticalChanged =
                      t.dominantHeadwordParentheticalQualifier != parenthetical;
                  parenthetical = t.dominantHeadwordParentheticalQualifier;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parentheticalChanged)
                        Wrap(
                          children:
                              parentheticalTexts(context, parenthetical, false),
                        ),
                      _translationContent(
                        context,
                        t,
                        hasParenthetical && parenthetical != '',
                        translations.indexOf(t) + 1,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _translationContent(
      BuildContext context, Translation translation, bool indent, int i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Indent(
            child: translationLine(context, translation, i),
            size: indent ? null : 0.0),
        examplePhraseText(context, translation.examplePhrases),
      ],
    );
  }
}
