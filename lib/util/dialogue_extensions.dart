import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/clients/dialogue_builders.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/protobufs/dialogues.pb.dart';

extension TranslatableChapter on DialogueChapter {
  bool get hasSubChapters => dialogueSubChapters.first.englishTitle.isNotEmpty;

  String title(BuildContext context) =>
      TranslationModel.of(context).isEnglish ? englishTitle : spanishTitle;

  String oppositeTitle(BuildContext context) =>
      !TranslationModel.of(context).isEnglish ? englishTitle : spanishTitle;
}

extension TranslatableSubChapter on DialogueSubChapter {
  String title(BuildContext context) =>
      TranslationModel.of(context).isEnglish ? englishTitle : spanishTitle;

  String oppositeTitle(BuildContext context) =>
      !TranslationModel.of(context).isEnglish ? englishTitle : spanishTitle;
}

extension TranslatableDialogue on Dialogue {
  String content(BuildContext context) =>
      TranslationModel.of(context).isEnglish
          ? englishContent
          : spanishContent;

  String oppositeContent(BuildContext context) =>
      !TranslationModel.of(context).isEnglish
          ? englishContent
          : spanishContent;
}
