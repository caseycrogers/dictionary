// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/translation_mode.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/util/constants.dart';

class TranslationModeSelector extends StatelessWidget {
  const TranslationModeSelector({Key? key}) : super(key: key);

  static final GlobalKey _englishKey = GlobalKey();
  static final GlobalKey _spanishKey = GlobalKey();

  RenderBox _getBox(TranslationMode mode) {
    if (isEnglish(mode)) {
      return _englishKey.currentContext!.findRenderObject() as RenderBox;
    }
    return _spanishKey.currentContext!.findRenderObject() as RenderBox;
  }

  @override
  Widget build(BuildContext context) {
    final DictionaryModel pageModel = DictionaryModel.instance;
    final BoxDecoration decoration = BoxDecoration(
      color: Colors.black38,
      borderRadius: BorderRadius.circular(4),
    );
    return ValueListenableBuilder<double>(
      valueListenable: pageModel.pageOffset,
      builder: (context, pageOffset, _) {
        return Container(
          height: kButtonHeight,
          child: Stack(
            children: [
              if (pageOffset % 1 != 0)
                AnimatedPositioned(
                  left: lerpDouble(
                    0,
                    _getBox(TranslationMode.Spanish)
                        .localToGlobal(
                          Offset.zero,
                          ancestor: context.findRenderObject() as RenderBox,
                        )
                        .dx,
                    pageOffset,
                  )!,
                  child: Container(
                    width: lerpDouble(
                      _getBox(TranslationMode.English).size.width,
                      _getBox(TranslationMode.Spanish).size.width,
                      pageOffset,
                    )!,
                    height: kButtonHeight,
                    decoration: decoration,
                  ),
                  duration: const Duration(milliseconds: 100),
                ),
              Row(
                children: [
                  Container(
                    decoration: pageOffset == 0 ? decoration : null,
                    child: _Button(
                      TranslationMode.English,
                      key: _englishKey,
                    ),
                  ),
                  const SizedBox(width: _Button._buttonSpacing),
                  Container(
                    decoration: pageOffset == 1 ? decoration : null,
                    child: _Button(
                      TranslationMode.Spanish,
                      key: _spanishKey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Button extends StatelessWidget {
  const _Button(this.mode, {Key? key}) : super(key: key);

  static const double _buttonSpacing = 5;

  final TranslationMode mode;

  @override
  Widget build(BuildContext context) {
    final DictionaryModel dictionaryModel = DictionaryModel.instance;
    final bool isSelected =
        dictionaryModel.translationModel.value.translationMode == mode;
    return Container(
      height: kButtonHeight,
      child: TextButton(
        style: ButtonStyle(
          overlayColor: MaterialStateProperty.all(Colors.black38),
          splashFactory: NoSplash.splashFactory,
        ),
        onPressed: isSelected
            ? null
            : () {
              dictionaryModel.onTranslationModeChanged(mode);
            },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            mode == TranslationMode.English
                ? i18n.english.cap.get(context)
                : i18n.spanish.cap.get(context),
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}
