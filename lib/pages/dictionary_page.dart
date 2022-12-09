// Dart imports:
import 'dart:collection';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:rogers_dictionary/dictionary_app.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/pages/dialogues_page.dart';
import 'package:rogers_dictionary/util/focus_utils.dart';
import 'package:rogers_dictionary/util/layout_picker.dart';
import 'package:rogers_dictionary/widgets/adaptive_material.dart';
import 'package:rogers_dictionary/widgets/dictionary_banner_ad.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_app_bar.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab_bar.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab_bar_view.dart';
import 'bookmarks_page.dart';
import 'search_page.dart';

class DictionaryPage extends StatelessWidget {
  const DictionaryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unFocus();
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: DictionaryModel.instance.isDark,
        builder: (context, isDark, child) {
          return ValueListenableBuilder<TranslationModel>(
            valueListenable: DictionaryModel.instance.translationModel,
            builder: (context, model, tabBarView) {
              final ColorScheme scheme = DictionaryApp.schemeFor(
                model.translationMode,
                isDark,
              );
              return Theme(
                data: Theme.of(context).copyWith(colorScheme: scheme),
                child: child!,
              );
            },
          );
        },
        child: AdaptiveMaterial(
          adaptiveColor: AdaptiveColor.primary,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                const DictionaryAppBar(),
                // Intentionally don't wrap this in theme, it'll cause
                // excess rebuilds.
                Expanded(
                  child: DictionaryTabBarView(
                    children: LinkedHashMap<DictionaryTab, Widget>.of(
                      {
                        DictionaryTab.search: SearchPage(),
                        DictionaryTab.bookmarks: BookmarksPage(),
                        DictionaryTab.dialogues: DialoguesPage(),
                      },
                    ),
                  ),
                ),
                const DictionaryBannerAd(),
              ],
            ),
            bottomNavigationBar: !isBigEnoughForAdvanced(context)
                ? const AdaptiveMaterial(
                    adaptiveColor: AdaptiveColor.primary,
                    child: SafeArea(
                      child: DictionaryTabBar(),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
