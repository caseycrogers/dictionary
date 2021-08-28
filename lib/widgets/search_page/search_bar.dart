import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/clients/speech_to_text.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/entry_search_model.dart';
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
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

  StreamSubscription? _speechToTextSubscription;
  late final ValueNotifier<Stream<RecordingUpdate>?> _currSpeechStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final SearchPageModel searchPageModel = DictionaryModel.readFrom(context)
        .translationModel
        .value
        .searchPageModel;

    if (_shouldInit) {
      _controller = TextEditingController(text: searchPageModel.searchString);
      _currSpeechStream =
          searchPageModel.entrySearchModel.currSpeechToTextStream;
      _currSpeechStream.addListener(_onNewStream);
      _controller.addListener(_updateIsEmpty);
      _isEmpty = searchPageModel.searchString.isEmpty;
      _shouldInit = false;
    }
  }

  @override
  void dispose() {
    _currSpeechStream.removeListener(_onNewStream);
    _currSpeechStream.value = null;
    DictionaryApp.speechToText.stop();
    _speechToTextSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TranslationModel>(
      valueListenable: DictionaryModel.of(context).translationModel,
      builder: (context, translationPage, content) {
        return Material(
          color: primaryColor(translationPage.translationMode),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: content!),
                RecordButton(
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
      .translationModel
      .value
      .searchPageModel
      .entrySearchModel;

  void _updateIsEmpty() {
    if (_isEmpty != _controller.text.isEmpty) {
      setState(() => _isEmpty = _controller.text.isEmpty);
    }
  }

  void _onNewStream() {
    final SearchPageModel searchPageModel =
        DictionaryModel.readFrom(context)
            .translationModel
            .value
            .searchPageModel;
    final Stream<RecordingUpdate>? speechStream =
        searchPageModel.entrySearchModel.currSpeechToTextStream.value;
    if (speechStream == null) {
      return;
    }
    _speechToTextSubscription = speechStream.listen(
          (speechUpdate) {
        if (speechUpdate.text.isNotEmpty) {
          _controller.text = speechUpdate.text;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: speechUpdate.text.length),
          );
          searchPageModel.entrySearchModel.onSearchStringChanged(
            context: context,
            newSearchString: speechUpdate.text,
          );
        }
      },
    );
  }
}
