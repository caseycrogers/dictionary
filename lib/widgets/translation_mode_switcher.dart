import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/main.dart';

import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/translation_mode.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/widgets/dictionary_banner_ad.dart';

class TranslationModeSwitcher extends StatefulWidget {
  const TranslationModeSwitcher({
    required this.child,
    this.header,
    this.keywordNotifier,
  });

  final Widget child;

  final Widget? header;

  final ValueNotifier<List<String>>? keywordNotifier;

  @override
  _TranslationModeSwitcherState createState() =>
      _TranslationModeSwitcherState();
}

class _TranslationModeSwitcherState extends State<TranslationModeSwitcher> {
  PageController? _controller;

  @override
  void didChangeDependencies() {
    if (_controller == null) {
      final DictionaryModel dictionaryModel = DictionaryModel.of(context);
      _controller = PageController(
        keepPage: false,
        initialPage:
            translationModeToIndex(dictionaryModel.currTranslationMode),
        viewportFraction: (MediaQuery.of(context).size.width + .25) /
            MediaQuery.of(context).size.width,
      );
      _controller!.addListener(() {
        dictionaryModel.pageOffset.value = _controller!.page!;
      });
      dictionaryModel.translationModel.addListener(() {
        final int targetPage = translationModeToIndex(
            dictionaryModel.translationModel.value.translationMode);
        // If the controller isn't attached yet then the PageView will be
        // properly constructed via initialPage.
        if (!_controller!.hasClients ||
            _controller!.page!.round() == targetPage) {
          return;
        }
        _controller!.jumpToPage(targetPage);
        //_controller!.animateToPage(
        //  targetPage,
        //  duration: const Duration(milliseconds: 200),
        //  curve: Curves.easeIn,
        //);
      });
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          if (widget.header != null) widget.header!,
          //DictionaryBannerAd(keywordNotifier: widget.keywordNotifier),
          Expanded(child: pages(context)),
        ],
      ),
      elevation: kHighElevation,
    );
  }

  Widget pages(BuildContext context) {
    final DictionaryModel dictionaryModel = DictionaryModel.of(context);
    // Used to force rebuilds on phone rotation. Otherwise translation mode
    // switcher gets messed up.
    return LayoutBuilder(
      builder: (context, constraints) {
        return PageView(
          controller: _controller,
          onPageChanged: (int index) => DictionaryModel.of(context)
              .onTranslationModeChanged(context, indexToTranslationMode(index)),
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: englishColorScheme,
              ),
              child: Row(
                children: [
                  Expanded(
                      key: const PageStorageKey<TranslationMode>(
                        TranslationMode.English,
                      ),
                      child: TranslationModelProvider(
                        translationModel: dictionaryModel.englishPageModel,
                        child: widget.child,
                      )),
                  const VerticalDivider(width: .25, thickness: .25),
                ],
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: spanishColorScheme,
              ),
              child: Row(
                children: [
                  const VerticalDivider(width: .25, thickness: .25),
                  Expanded(
                    key: const PageStorageKey<TranslationMode>(
                      TranslationMode.Spanish,
                    ),
                    child: TranslationModelProvider(
                      translationModel: dictionaryModel.spanishPageModel,
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class TranslationModelProvider extends StatelessWidget {
  const TranslationModelProvider({
    Key? key,
    required this.translationModel,
    required this.child,
  }) : super(key: key);

  final TranslationModel translationModel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

bool isCurrentTranslationPage(BuildContext context) {
  return TranslationModel.of(context) ==
      DictionaryModel.of(context).currTranslationModel;
}
