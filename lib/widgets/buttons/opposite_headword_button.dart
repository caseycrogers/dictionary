import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';

class OppositeHeadwordButton extends StatelessWidget {
  const OppositeHeadwordButton({
    Key? key,
    required this.translation,
  }) : super(key: key);

  final Translation translation;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: () {
        DictionaryModel.of(context).onOppositeHeadwordSelected(
          context,
          EntryUtils.urlEncode(translation.getOppositeHeadword),
        );
      },
      icon: Icon(
        Icons.open_in_new,
        color: Theme
            .of(context)
            .accentIconTheme
            .color,
        size: Theme
            .of(context)
            .accentIconTheme
            .size,
      ),
    );
  }
}
