import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rogers_dictionary/dictionary/search_bar.dart';
import 'package:rogers_dictionary/dictionary/search_string_model.dart';
import 'package:rogers_dictionary/entry_database/entry.dart';
import 'package:rogers_dictionary/main.dart';

import '../dictionary/entry_list.dart';

class DictionaryPage extends StatelessWidget {
  static const String route = '/';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SearchStringModel(),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Dictionary'),
          ),
          body: Column(children: [
            SearchBar(),
            Flexible(
              child: Consumer<SearchStringModel> (
                builder: (context, searchStringModel, child) => EntryList(_getEntries(searchStringModel.searchString)),
              ),
            ),
          ]),
        );
      },
    );
  }

  Stream<List<Entry>> _getEntries(String searchString) =>
      MyApp.db.getEntries(searchString: searchString);
}