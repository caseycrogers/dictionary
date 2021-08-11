import 'dart:core';
import 'dart:ui';

import 'package:async_list_view/async_list_view.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/entry_database/entry_builders.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/entry_search_model.dart';
import 'package:rogers_dictionary/models/search_page_model.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';
import 'package:rogers_dictionary/pages/dictionary_page.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/util/delayed.dart';
import 'package:rogers_dictionary/widgets/buttons/open_page.dart';
import 'package:rogers_dictionary/widgets/loading_text.dart';
import 'package:rogers_dictionary/widgets/search_page/entry_view.dart';

class EntryList extends StatelessWidget {
  const EntryList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable:
          SearchPageModel.of(context).entrySearchModel.currSearchString,
      builder: (context, _, __) {
        final SearchPageModel searchPageModel = SearchPageModel.of(context);
        final EntrySearchModel entrySearchModel =
            searchPageModel.entrySearchModel;
        if (entrySearchModel.isEmpty &&
            DictionaryModel.of(context).currentTab.value ==
                DictionaryTab.search) {
          return _noResultsWidget(i18n.enterTextHint.get(context), context);
        }
        return AsyncListView<Entry>(
          // Maintains scroll state
          key: PageStorageKey('entry_list'
              '-bookmarks${entrySearchModel.isBookmarkedOnly}'
              '-${searchPageModel.translationMode}'),
          padding: EdgeInsets.zero,
          noResultsWidgetBuilder: (context) => _noResultsWidget(
              entrySearchModel.isBookmarkedOnly
                  ? i18n.noBookmarksHint.get(context)
                  : i18n.typosHint.get(context),
              context),
          initialData: entrySearchModel.entries,
          stream: entrySearchModel.entryStream,
          loadingWidget: Delayed(
            delay: const Duration(milliseconds: 100),
            initialChild: Container(),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingText(),
            ),
          ),
          itemBuilder: _buildRow,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context,
    AsyncSnapshot<List<Entry>> snapshot,
    int index,
  ) {
    final dictionaryModel = DictionaryModel.readFrom(context);
    final SearchPageModel searchPageModel = SearchPageModel.readFrom(context);
    return ValueListenableBuilder<SelectedEntry?>(
      valueListenable: searchPageModel.currSelectedEntry,
      builder: (context, selectedEntry, _) {
        if (snapshot.hasError) {
          print(snapshot.error);
        }
        if (!snapshot.hasData) {
          return const LoadingText();
        }
        final entry = snapshot.data![index];
        final bool isSelected = entry.headword.urlEncodedHeadword ==
            selectedEntry?.urlEncodedHeadword;
        final bool shouldHighlight =
            MediaQuery.of(context).orientation == Orientation.landscape &&
                isSelected;
        return Column(
          children: [
            InkWell(
                child: Material(
                  color: shouldHighlight
                      ? Theme.of(context).selectedRowColor
                      : Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: EntryView.asPreview(entry)),
                        OpenPage(),
                      ],
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    ),
                  ),
                ),
                onTap: isSelected
                    ? null
                    : () {
                        dictionaryModel.onEntrySelected(context, entry);
                      }),
            if (index < snapshot.data!.length - 1)
              const Divider(
                thickness: 1,
                height: 1,
              ),
          ],
        );
      },
    );
  }

  Widget _noResultsWidget(String text, BuildContext context) {
    final TranslationPageModel pageModel = TranslationPageModel.of(context);
    final String swipeText = pageModel.isEnglish
        ? i18n.swipeLeft.get(context)
        : i18n.swipeRight.get(context);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2 * kPad),
          child: Text(
            '\n\n$text$swipeText',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        const Icon(Icons.swipe, color: Colors.grey),
      ],
    );
  }
}
