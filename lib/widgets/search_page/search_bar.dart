import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/entry_search_model.dart';
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/util/constants.dart';

class SearchBar extends StatefulWidget {
  const SearchBar();

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _controller;

  late SearchModel _searchModel;

  bool _shouldInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchModel =
        DictionaryModel.of(context).translationModel.value.searchModel;

    if (_shouldInit) {
      _controller = TextEditingController(text: _searchModel.searchString);
      // Bidirectional listen. This won't create an infinite loop because it
      // only notifies listeners if the value is new.
      _controller.addListener(_onTextChanged);
      _searchModel.entrySearchModel.currSearchString
          .addListener(_onSearchChanged);
      _shouldInit = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchModel.entrySearchModel.currSearchString
        .removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TranslationModel>(
      valueListenable: DictionaryModel.of(context).translationModel,
      builder: (context, translationPage, child) {
        return child!;
      },
      child: _SearchBarBase(controller: _controller),
    );
  }

  // Listener to update model if the local text has changed.
  void _onTextChanged() {
    final EntrySearchModel entrySearchModel = DictionaryModel.of(context)
        .currTranslationModel
        .searchModel
        .entrySearchModel;
    final bool oldIsEmpty = entrySearchModel.isEmpty;
    DictionaryModel.of(context)
        .currTranslationModel
        .searchModel
        .entrySearchModel
        .onSearchStringChanged(
          context: context,
          newSearchString: _controller.text,
        );
    if (oldIsEmpty != _controller.text.isEmpty) {
      setState(() {});
    }
  }

  // Listener to update local text if the model has changed.
  void _onSearchChanged() {
    final EntrySearchModel entrySearchModel = DictionaryModel.of(context)
        .currTranslationModel
        .searchModel
        .entrySearchModel;
    final String oldText = _controller.text;
    if (oldText != entrySearchModel.searchString) {
      _controller.text = entrySearchModel.searchString;
    }
    if (oldText.isEmpty != entrySearchModel.isEmpty) {
      setState(() {});
    }
  }
}

class _SearchBarBase extends StatelessWidget {
  const _SearchBarBase({Key? key, this.controller}) : super(key: key);

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(vertical: kPad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: TextField(
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodyText2!.fontSize,
            ),
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller?.text.isNotEmpty ?? false
                  ? IconButton(
                      onPressed: () {
                        controller?.clear();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              hintText: '${i18n.search.get(context)}...',
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
