import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/widgets/translation_mode_switcher.dart';

import 'dialogues_page_model.dart';

enum TranslationMode {
  English,
  Spanish,
}

bool isEnglish(TranslationMode mode) => mode == TranslationMode.English;

TranslationMode oppositeMode(TranslationMode mode) =>
    isEnglish(mode) ? TranslationMode.Spanish : TranslationMode.English;

class TranslationModel {
  TranslationModel({
    required this.translationMode,
  })
      : searchPageModel = SearchModel(
    mode: translationMode,
    isBookmarkedOnly: false,
  ),
        bookmarksPageModel = SearchModel(
          mode: translationMode,
          isBookmarkedOnly: true,
        ),
        layerLink = LayerLink();

  // Translation mode state.
  final TranslationMode translationMode;

  final SearchModel searchPageModel;

  final SearchModel bookmarksPageModel;

  final LayerLink layerLink;

  static final DialoguesPageModel _dialoguesPageModel = DialoguesPageModel();

  DialoguesPageModel get dialoguesPageModel => _dialoguesPageModel;

  bool get isEnglish => translationMode == TranslationMode.English;

  static TranslationModel of(BuildContext context) {
    return context
        .findAncestorWidgetOfExactType<TranslationModelProvider>()!
        .translationModel;
  }
}
