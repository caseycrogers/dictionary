import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/widgets/buttons/help_menu.dart';
import 'package:rogers_dictionary/widgets/buttons/translation_mode_selector.dart';

class DictionaryTopBar extends StatelessWidget {
  const DictionaryTopBar({
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DictionaryModel dictionaryModel = DictionaryModel.of(context);
    return ValueListenableBuilder<TranslationModel>(
      valueListenable: dictionaryModel.translationModel,
      builder: (context, translationPageModel, _) => Material(
        color: primaryColor(translationPageModel.translationMode),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: const [
              TranslationModeSelector(),
              Spacer(),
              HelpMenu(),
            ],
          ),
        ),
      ),
    );
  }
}
