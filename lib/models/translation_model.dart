import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/models/translation_mode.dart';
import 'package:rogers_dictionary/widgets/translation_mode_switcher.dart';

import 'dialogues_page_model.dart';

bool isEnglish(TranslationMode mode) => mode == TranslationMode.English;

TranslationMode oppositeMode(TranslationMode mode) =>
    isEnglish(mode) ? TranslationMode.Spanish : TranslationMode.English;

class TranslationModel {
  TranslationModel({
    required this.translationMode,
  })  : searchModel = SearchModel(
          mode: translationMode,
          isBookmarksOnly: false,
        ),
        bookmarksPageModel = SearchModel(
          mode: translationMode,
          isBookmarksOnly: true,
        ),
        layerLink = LayerLink();

  // Translation mode state.
  final TranslationMode translationMode;

  final SearchModel searchModel;

  final SearchModel bookmarksPageModel;

  final LayerLink layerLink;

  static final DialoguesPageModel _dialoguesPageModel = DialoguesPageModel();

  DialoguesPageModel get dialoguesPageModel => _dialoguesPageModel;

  bool get isEnglish => translationMode == TranslationMode.English;

  static TranslationModel of(BuildContext context) {
    final TranslationModel? translationModel = context
        .findAncestorWidgetOfExactType<TranslationModelProvider>()
        ?.translationModel;
    assert(
      translationModel != null,
      'Could not find a translation model above this widget.',
    );
    return context
        .findAncestorWidgetOfExactType<TranslationModelProvider>()!
        .translationModel;
  }
}
