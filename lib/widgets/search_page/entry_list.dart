import 'dart:core';

import 'package:async_list_view/async_list_view.dart';
import 'package:flutter/material.dart';
import 'package:implicit_navigator/implicit_navigator.dart';

import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/util/delayed.dart';
import 'package:rogers_dictionary/util/layout_picker.dart';
import 'package:rogers_dictionary/util/value_notifier_extension.dart';
import 'package:rogers_dictionary/widgets/buttons/open_page.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab.dart';
import 'package:rogers_dictionary/widgets/loading_text.dart';
import 'package:rogers_dictionary/widgets/no_results_widget.dart';
import 'package:rogers_dictionary/widgets/search_page/entry_view.dart';

class EntryList extends StatelessWidget {
  const EntryList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We need access to this below to ensure entries are cached to the write
    // page storage.
    final SearchModel searchModel = SearchModel.of(context);
    final BuildContext cacheContext = context;
    return ImplicitNavigator<_SearchResults>.fromNotifier(
      key: const PageStorageKey('search_string_navigator'),
      valueNotifier:
          searchModel.entrySearchModel.currSearchString.map<_SearchResults>(
        (searchString) => _SearchResults(context, searchString),
        (searchResults) => searchResults.searchString,
      ),
      getDepth: (searchResults) {
        return searchResults.searchString.isEmpty ? 0 : 1;
      },
      // This breaks if duration is zero.
      transitionDuration: const Duration(milliseconds: 1),
      builder: (context, searchResults, _, __) {
        return AsyncListView<Entry>(
          // Maintains scroll state
          key: const PageStorageKey('entry_list'),
          padding: EdgeInsets.zero,
          noResultsWidgetBuilder: (context) => const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2 * kPad),
              child: NoResultsWidget(),
            ),
          ),
          stream: searchResults.entryStream,
          initialData: searchResults.cachedEntries,
          loadingWidget: Delayed(
            delay: const Duration(milliseconds: 100),
            initialChild: Container(),
            child: const Padding(
              padding: EdgeInsets.all(kPad),
              child: LoadingText(),
            ),
          ),
          itemBuilder: (context, snapshot, index) {
            if (snapshot.hasData) {
              // Use the outer context to get access to the correct pageStorage.
              searchResults.writeToCache(cacheContext, snapshot.data!);
            }
            return _buildRow(context, snapshot, index);
          },
        );
      },
    );
  }
}

Widget _buildRow(
  BuildContext context,
  AsyncSnapshot<List<Entry>> snapshot,
  int index,
) {
  final dictionaryModel = DictionaryModel.of(context);
  final SearchModel searchPageModel = SearchModel.of(context);
  searchPageModel.entrySearchModel.entries = snapshot.data ?? <Entry>[];
  final Widget row = ValueListenableBuilder<SelectedEntry?>(
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
          isBigEnoughForAdvanced(context) && isSelected;
      return Column(
        children: [
          InkWell(
              child: Material(
                color: shouldHighlight
                    ? Theme.of(context).selectedRowColor
                    : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2 * kPad),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2 * kPad,
                          ).subtract(
                            const EdgeInsets.only(top: (2 * kPad) - 1),
                          ),
                          child: EntryView.asPreview(entry),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2 * kPad,
                        ),
                        child: OpenPage(),
                      ),
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

  // Put no results widget at top
  if (index == 0 &&
      SearchModel.of(context).entrySearchModel.isEmpty &&
      dictionaryModel.currentTab.value == DictionaryTab.search) {
    return Column(children: [
      const CollapsingNoResultsWidget(),
      const Divider(height: 0),
      row,
    ]);
  }
  return row;
}

@immutable
class _SearchResults {
  _SearchResults(
    BuildContext context,
    this.searchString,
  ) {
    final _CachedResults? results =
        PageStorage.of(context)!.readState(context) as _CachedResults?;
    if (SearchModel.of(context).entrySearchModel.isDirty() ||
        results?.searchString != searchString) {
      cachedEntries = [];
    } else {
      cachedEntries = results!.entries;
    }
    entryStream = SearchModel.of(context)
        .entrySearchModel
        .newStream(startAt: cachedEntries.length);
  }

  final String searchString;
  late final List<Entry> cachedEntries;
  late final Stream<Entry> entryStream;

  void writeToCache(BuildContext context, List<Entry> entries) {
    PageStorage.of(context)!.writeState(
      context,
      _CachedResults(searchString, entries),
    );
  }
}

@immutable
class _CachedResults {
  const _CachedResults(this.searchString, this.entries);

  final String searchString;
  final List<Entry> entries;
}
