import 'package:flutter/cupertino.dart';
import 'package:rogers_dictionary/entry_database/entry.dart';
import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_page_model.dart';
import 'package:rogers_dictionary/models/search_options.dart';

class EntrySearchModel with ChangeNotifier {
  // Duplicated here because we need it to construct the entry stream.
  final TranslationMode _translationMode;
  String _searchString;
  SearchOptions _searchOptions;
  String _startAfter;
  Stream<Entry> _entryStream;
  List<Entry> _entries;
  ScrollController _scrollController;

  String get searchString => _searchString;

  SearchOptions get searchOptions => _searchOptions;

  String get startAfter => _startAfter;

  Stream<Entry> get entryStream => _entryStream;

  List<Entry> get entries => _entries;

  ScrollController get scrollController => _scrollController;

  bool get isEmpty => _searchString.isEmpty;

  EntrySearchModel._(
      this._translationMode,
      this._searchString,
      this._searchOptions,
      this._startAfter,
      this._entries,
      this._scrollController) {
    _entryStream = MyApp.db.getEntries(_translationMode,
        searchString: searchString,
        startAfter: startAfter,
        searchOptions: searchOptions);
  }

  EntrySearchModel(TranslationMode translationMode, String searchString,
      SearchOptions searchOptions)
      : this._(translationMode, searchString, searchOptions, '', [],
            ScrollController());

  EntrySearchModel.empty(TranslationMode translationMode)
      : this._(translationMode, '', SearchOptions.empty(), '', [],
            ScrollController());

  EntrySearchModel copy() => EntrySearchModel._(
      _translationMode,
      _searchString,
      _searchOptions,
      _startAfter,
      _entries,
      ScrollController(
          initialScrollOffset:
              _scrollController.hasClients ? _scrollController.offset : 0.0));

  void onSearchStringChanged(
      String newSearchString, SearchOptions newSearchOptions) {
    // Do nothing if nothing has changed
    if (_searchString == newSearchString && _searchOptions == newSearchOptions)
      return;
    _searchString = newSearchString;
    _searchOptions = newSearchOptions;
    _startAfter = '';
    _entries = [];
    _entryStream = MyApp.db.getEntries(_translationMode,
        searchString: _searchString,
        startAfter: _startAfter,
        searchOptions: _searchOptions);
    _scrollController = ScrollController();
    notifyListeners();
  }

  void updateEntries(newEntries) {
    _entries = newEntries;
    _startAfter = _entries.isNotEmpty ? _entries.last.urlEncodedHeadword : '';
  }
}
