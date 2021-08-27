import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/entry_search_model.dart';
import 'package:rogers_dictionary/models/search_page_model.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';
import 'package:rogers_dictionary/widgets/buttons/record_button.dart';

class SearchBar extends StatefulWidget {
  const SearchBar();

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _controller;
  late bool _isEmpty;

  bool _shouldInit = true;

  final StreamController<String> _speechToTextStreamController =
      StreamController();
  late final StreamSubscription _speechToTextSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final SearchPageModel searchPageModel = DictionaryModel.readFrom(context)
        .translationPageModel
        .value
        .searchPageModel;
    if (_shouldInit) {
      _controller = TextEditingController(text: searchPageModel.searchString);
      _speechToTextSubscription = _speechToTextStreamController.stream.listen(
        (text) {
          if (text.isNotEmpty) {
            _controller.text = text;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
            searchPageModel.entrySearchModel.onSearchStringChanged(
              context: context,
              newSearchString: text,
            );
          }
        },
      );
      _controller.addListener(_updateIsEmpty);
      _isEmpty = searchPageModel.searchString.isEmpty;
      _shouldInit = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _speechToTextSubscription.cancel();
    _speechToTextStreamController.close();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TranslationPageModel>(
      valueListenable: DictionaryModel.of(context).translationPageModel,
      builder: (context, translationPage, content) {
        return Material(
          color: primaryColor(translationPage.translationMode),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: content!),
                RecordButton(
                  outputStreamController: _speechToTextStreamController,
                  mode: translationPage.translationMode,
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          color: Theme.of(context).backgroundColor,
          child: TextField(
            style: const TextStyle(fontSize: 20),
            controller: _controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _controller.clear();
                        entrySearchModel.onSearchStringChanged(
                          context: context,
                          newSearchString: '',
                        );
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              hintText: '${i18n.search.get(context)}...',
              border: InputBorder.none,
            ),
            onChanged: (searchString) {
              entrySearchModel.onSearchStringChanged(
                context: context,
                newSearchString: searchString,
              );
            },
          ),
        ),
      ),
    );
  }

  EntrySearchModel get entrySearchModel => DictionaryModel.readFrom(context)
      .translationPageModel
      .value
      .searchPageModel
      .entrySearchModel;

  void _updateIsEmpty() {
    if (_isEmpty != _controller.text.isEmpty) {
      setState(() => _isEmpty = _controller.text.isEmpty);
    }
  }
}
