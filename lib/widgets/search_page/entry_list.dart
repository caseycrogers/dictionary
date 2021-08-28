import 'dart:core';
import 'dart:ui';

import 'package:async_list_view/async_list_view.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/entry_search_model.dart';
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/pages/dictionary_page.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'package:rogers_dictionary/util/delayed.dart';
import 'package:rogers_dictionary/widgets/buttons/open_page.dart';
import 'package:rogers_dictionary/widgets/loading_text.dart';
import 'package:rogers_dictionary/widgets/no_results_widget.dart';
import 'package:rogers_dictionary/widgets/search_page/entry_view.dart';

class EntryList extends StatefulWidget {
  const EntryList({Key? key}) : super(key: key);

  @override
  _EntryListState createState() => _EntryListState();
}

class _EntryListState extends State<EntryList> {
  late Stream<Entry> _entryStream;
  List<Entry> _initialData = [];

  late final VoidCallback _disposeListener;

  void _initializeStream() {
    _initialData = [];
    final EntrySearchModel entrySearchModel =
        SearchModel.of(context).entrySearchModel;
    final _EntryListStorableState? cached = _EntryListStorableState.of(context);
    if (!SearchModel.of(context).entrySearchModel.isDirty() &&
        cached != null &&
        cached.searchString == entrySearchModel.searchString) {
      _initialData = cached.entries ?? [];
    }
    _entryStream = entrySearchModel.newStream(startAt: _initialData.length);
  }

  void _onSearchStringChanged() {
    setState(() {
      _initializeStream();
    });
  }

  @override
  void initState() {
    _initializeStream();
    final ValueNotifier<String> currSearchString =
        SearchModel.of(context).entrySearchModel.currSearchString;
    currSearchString.addListener(_onSearchStringChanged);
    _disposeListener =
        () => currSearchString.removeListener(_onSearchStringChanged);
    super.initState();
  }

  @override
  void dispose() {
    _disposeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncListView<Entry>(
      // Maintains scroll state
      key: const PageStorageKey('list_view'),
      padding: EdgeInsets.zero,
      noResultsWidgetBuilder: (context) => const SingleChildScrollView(
        child: NoResultsWidget(),
      ),
      stream: _entryStream,
      initialData: _initialData,
      loadingWidget: Delayed(
        delay: const Duration(milliseconds: 100),
        initialChild: Container(),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: LoadingText(),
        ),
      ),
      itemBuilder: _buildRow,
    );
  }

  Widget _buildRow(
    BuildContext rowContext,
    AsyncSnapshot<List<Entry>> snapshot,
    int index,
  ) {
    final dictionaryModel = DictionaryModel.of(rowContext);
    final SearchModel searchPageModel = SearchModel.of(rowContext);
    _EntryListStorableState.write(
      context,
      searchPageModel.entrySearchModel.searchString,
      snapshot.data,
    );
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

    // Put no results widget at top
    if (index == 0 &&
        SearchModel.of(context).entrySearchModel.isEmpty &&
        dictionaryModel.currentTab.value == DictionaryTab.search) {
      return Column(children: [
        const NoResultsWidget(),
        const Divider(height: 0),
        row,
      ]);
    }
    return row;
  }
}

@immutable
class _EntryListStorableState {
  const _EntryListStorableState(this.searchString, this.entries);

  final String searchString;
  final List<Entry>? entries;

  static _EntryListStorableState? of(BuildContext context) {
    return PageStorage.of(context)!.readState(
      context,
    ) as _EntryListStorableState?;
  }

  static void write(
    BuildContext context,
    String searchString,
    List<Entry>? entries,
  ) {
    PageStorage.of(context)!.writeState(
      context,
      _EntryListStorableState(searchString, entries),
    );
  }
}
