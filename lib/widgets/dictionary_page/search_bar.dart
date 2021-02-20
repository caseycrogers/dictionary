import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_page_model.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/search_options_button.dart';

class SearchBar extends StatefulWidget {
  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  FocusNode _focusNode;
  TextEditingController _controller;
  bool _isEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final searchPageModel = context.read<SearchPageModel>();
    if (_focusNode == null) {
      _focusNode = FocusNode();
      if (searchPageModel.searchBarHasFocus)
        //_focusNode.requestFocus();
        _focusNode.addListener(
            () => searchPageModel.searchBarHasFocus = _focusNode.hasFocus);
      _controller = TextEditingController(text: searchPageModel.searchString);
      _controller.addListener(_updateIsEmpty);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dictionaryModel = DictionaryPageModel.of(context);
    final searchPageModel = SearchPageModel.of(context);
    return Material(
      color: searchPageModel.isEnglish ? englishPrimary : spanishPrimary,
      child: Padding(
        padding: EdgeInsets.all(8.0).subtract(EdgeInsets.only(right: 8.0)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: Container(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40.0),
                  child: Container(
                    color: Theme.of(context).backgroundColor,
                    child: TextField(
                      focusNode: _focusNode,
                      style: TextStyle(fontSize: 20.0),
                      controller: _controller,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _controller.clear();
                                  DictionaryPageModel.of(context)
                                      .onSearchChanged(newSearchString: '');
                                },
                                icon: Icon(Icons.clear),
                              )
                            : null,
                        hintText: 'search...',
                        border: InputBorder.none,
                      ),
                      onChanged: (searchString) => dictionaryModel
                          .onSearchChanged(newSearchString: searchString),
                    ),
                  ),
                ),
              ),
            ),
            SearchOptionsButton(),
          ],
        ),
      ),
    );
  }

  void _updateIsEmpty() {
    if (_isEmpty != _controller.text.isEmpty)
      setState(() => _isEmpty = _controller.text.isEmpty);
  }
}
