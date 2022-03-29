import 'dart:async';
import 'dart:convert';

import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rogers_dictionary/clients/dialogue_builders.dart';
import 'package:rogers_dictionary/dictionary_app.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dialogues_page_model.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/models/entry_search_model.dart';
import 'package:rogers_dictionary/models/translation_mode.dart';
import 'package:rogers_dictionary/pages/dialogues_page.dart';
import 'package:rogers_dictionary/protobufs/dialogues.pb.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';
import 'package:rogers_dictionary/screenshot_template.dart';
import 'package:rogers_dictionary/util/collection_utils.dart';
import 'package:rogers_dictionary/util/string_utils.dart';
import 'package:rogers_dictionary/widgets/dialogues_page/chapter_view.dart';
import 'package:rogers_dictionary/widgets/dictionary_page/dictionary_tab.dart';
import 'package:rogers_dictionary/widgets/search_page/entry_view.dart';
import 'package:rogers_dictionary/widgets/search_page/selected_entry_switcher.dart';
import 'package:rogers_dictionary/widgets/translation_mode_switcher.dart';

import '../test_driver/screenshots_test.dart';

const Locale en = Locale('en', '');
const Locale es = Locale('es', '');

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;
  DictionaryModel dictionaryModel = DictionaryModel.instance;

  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await initialize();
    await DictionaryApp.analytics.setAnalyticsCollectionEnabled(false);
    await binding.convertFlutterSurfaceToImage();
  });

  tearDown(() {
    DictionaryModel.reset();
    EntrySearchModel.reset();
    dictionaryModel = DictionaryModel.instance;
  });

  for (final Locale locale in [
    en,
    es,
  ]) {
    for (final ScreenshotConfig config in [
      // ios.
      ScreenshotConfig(
        device: Devices.ios.iPhone13ProMax,
        outputWidth: 1284,
        outputHeight: 2778,
      ),
      ScreenshotConfig(device: Devices.ios.iPadPro11Inches),
      // Android.
      ScreenshotConfig(device: Devices.android.onePlus8Pro),
    ]) {
      String screenshotName(String suffix) {
        return jsonEncode(
          ScreenshotIdentifier(
            path: [
              config.device.identifier.platform.name.enumString,
              config.device.identifier.name,
              locale.languageCode,
              suffix,
            ],
            width: config.outputWidth.toInt(),
            height: config.outputHeight.toInt(),
            offsetY: kTopPad.toInt(),
          ),
        );
      }

      testWidgets('English search page ($locale) (${config.device.name}).',
          (WidgetTester tester) async {
        // English search page.
        await tester.pumpWidget(
          DictionaryScreenshotTemplate(
            headerText: const i18n.Message(
              'Search for 15k+ English medical translations!',
              '¡Busca más de 15k traducciones médicas en inglés!',
            ),
            config: config,
            locale: locale,
          ),
        );
        final BuildContext context = await pumpUntilFound(
          tester,
          find.byHeadword('abdomen'),
        );
        if (config.isLargeScreen) {
          dictionaryModel.onHeadwordSelected(context, 'abdomen');
          // Wait until the widget has animated out of view.
          await pumpUntilNotFound(tester, find.byType(NoEntryBackground));
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await binding.takeScreenshot(screenshotName('01-az_en'));
      });

      testWidgets('Spanish search page ($locale) (${config.device.name}).',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          DictionaryScreenshotTemplate(
            headerText: const i18n.Message(
              '...and 15k+ Spanish medical translations!',
              '...y más de 15k traducciones médicas al español!',
            ),
            config: config,
            locale: locale,
          ),
        );
        dictionaryModel.onTranslationModeChanged();
        final BuildContext context = await pumpUntilFound(
          tester,
          find.byHeadword('abandono del tabaco'),
        );
        if (config.isLargeScreen) {
          dictionaryModel.onHeadwordSelected(context, 'abandono del tabaco');
          await pumpUntilNotFound(tester, find.byType(NoEntryBackground));
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await binding.takeScreenshot(screenshotName('02-az_es'));
      });

      testWidgets('Bookmarks ($locale) (${config.device.name}).',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          DictionaryScreenshotTemplate(
            headerText: const i18n.Message(
              'Bookmark words to study!',
              '¡Marca palabras para estudiar!',
            ),
            config: config,
            locale: locale,
          ),
        );
        dictionaryModel.onTranslationModeChanged();
        BuildContext context = await pumpUntilFound(
          tester,
          find.byHeadword('abandono del tabaco'),
        );
        context = await findAndBookmark(
            context, tester, TranslationMode.Spanish, 'pie');
        context = await findAndBookmark(
            context, tester, TranslationMode.Spanish, 'brazo');
        context = await findAndBookmark(
            context, tester, TranslationMode.Spanish, 'pierna');
        context = await findAndBookmark(
            context, tester, TranslationMode.Spanish, 'rodilla');
        context = await findAndBookmark(
            context, tester, TranslationMode.Spanish, 'cabeza');
        context = await findAndBookmark(
            context, tester, TranslationMode.Spanish, 'nariz');

        dictionaryModel.currentTab.value = DictionaryTab.bookmarks;
        if (config.isLargeScreen) {
          dictionaryModel.onHeadwordSelected(context, 'pie');
          await pumpUntilNotFound(tester, find.byType(NoEntryBackground));
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await binding.takeScreenshot(screenshotName('03-bookmarks_es'));
      });

      testWidgets('Dialogue Chapters ($locale) (${config.device.name}).',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          DictionaryScreenshotTemplate(
            headerText: const i18n.Message(
              'Translated medical dialogues!',
              '¡Diálogos médicos traducidos!',
            ),
            config: config,
            locale: locale,
          ),
        );
        dictionaryModel.currentTab.value = DictionaryTab.dialogues;
        await pumpUntilFound(
          tester,
          find.byType(DialoguesPage),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await binding.takeScreenshot(screenshotName('04-chapters_en'));
      });

      testWidgets('Dialogues ($locale) (${config.device.name}).',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          DictionaryScreenshotTemplate(
            headerText: const i18n.Message(
              'Translated medical dialogues!',
              '¡Diálogos médicos traducidos!',
            ),
            config: config,
            locale: locale,
          ),
        );
        final DialoguesPageModel dialoguesModel =
            dictionaryModel.translationModel.value.dialoguesPageModel;
        dictionaryModel.currentTab.value = DictionaryTab.dialogues;
        final DialogueChapter chapter = await pumpUntil(
          tester,
          () {
            return dialoguesModel.dialogues
                .where((chapter) {
                  return chapter.englishTitle == 'History and Physical';
                })
                .emptyToNull
                ?.first;
          },
        );
        final DialogueSubChapter subChapter =
            chapter.dialogueSubChapters.firstWhere((subChapter) {
          return subChapter.englishTitle == 'Past Medical History';
        });
        final BuildContext context = await pumpUntilFound(
          tester,
          find.byType(DialoguesPage),
        );
        dialoguesModel.onChapterSelected(context, chapter, subChapter);
        await pumpUntilFound(
          tester,
          find.byType(ChapterView),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await binding.takeScreenshot(screenshotName('05-dialogues_en'));
      });

      testWidgets('Live search ($locale) (${config.device.name}).',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          DictionaryScreenshotTemplate(
            headerText: const i18n.Message(
              'Results appear as you type!',
              '¡Los resultados aparecen a medida que escribes!',
            ),
            config: config,
            locale: locale,
          ),
        );
        BuildContext context = await pumpUntilFound(
          tester,
          find.byHeadword('abdomen'),
        );
        dictionaryModel.currTranslationModel.searchModel.entrySearchModel
            .onSearchStringChanged(
          context: context,
          newSearchString: 'fl',
        );
        context = await pumpUntilFound(
          tester,
          find.byHeadword('flu'),
        );
        if (config.isLargeScreen) {
          dictionaryModel.onHeadwordSelected(context, 'flu');
          await pumpUntilNotFound(tester, find.byType(NoEntryBackground));
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await binding.takeScreenshot(screenshotName('06-search_en'));
      });

      testWidgets('Fullscreen entry ($locale) (${config.device.name}).',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          DictionaryScreenshotTemplate(
            headerText: const i18n.Message(
              'Detailed and comprehensive translations!',
              '¡Traducciones detalladas y completas!',
            ),
            config: config,
            locale: locale,
          ),
        );
        final BuildContext context = await pumpUntilFound(
          tester,
          find.byHeadword('abdomen'),
        );
        dictionaryModel.currTranslationModel.searchModel.entrySearchModel
            .onSearchStringChanged(
          context: context,
          newSearchString: 'str',
        );
        dictionaryModel.onHeadwordSelected(context, 'strain');
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await binding.takeScreenshot(screenshotName('07-complex_entry_en'));
      });

      testWidgets('Regional entry ($locale) (${config.device.name}).',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          DictionaryScreenshotTemplate(
            headerText: const i18n.Message(
              'Regionalized  translations!',
              '¡Traducciones regionalizadas!',
            ),
            config: config,
            locale: locale,
          ),
        );
        BuildContext context = await pumpUntilFound(
          tester,
          find.byHeadword('abdomen'),
        );
        dictionaryModel.currTranslationModel.searchModel.entrySearchModel
            .onSearchStringChanged(
          context: context,
          newSearchString: 'bug',
        );
        context = await pumpUntilFound(
          tester,
          find.byHeadword('kissing bug'),
        );
        dictionaryModel.onHeadwordSelected(context, 'kissing bug');
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await binding.takeScreenshot(screenshotName('08-regional_en'));
      });
    }
  }
}

Future<T> pumpUntil<T extends Object>(
  WidgetTester tester,
  T? Function() test, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  bool timerDone = false;
  final timer = Timer(
    timeout,
    () => throw TimeoutException('Pump until has timed out'),
  );
  T? result;
  while (timerDone != true) {
    await tester.pump();
    result = test();
    if (result != null) {
      timerDone = true;
    }
  }
  timer.cancel();
  // If we've broken out of the for loop result must be non-null.
  return result!;
}

extension FinderUtils on CommonFinders {
  Finder byHeadword(String headword) {
    return find.byWidgetPredicate((widget) =>
        widget is EntryViewPreview && widget.entry.headword.text == headword);
  }

  Finder byEntry(Entry entry) {
    return find.byWidgetPredicate(
        (widget) => widget is EntryViewPreview && widget.entry == entry);
  }

  Finder byTranslationMode(TranslationMode mode) {
    return find.byWidgetPredicate((widget) =>
        widget is TranslationModelProvider &&
        widget.translationModel.translationMode == mode);
  }
}

Future<Element> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) {
  return pumpUntil(
    tester,
    () {
      final Iterable<Element> elements = finder.evaluate();
      return elements.isEmpty ? null : elements.first;
    },
  );
}

Future<void> pumpUntilNotFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) {
  return pumpUntil(
    tester,
    () {
      final Iterable<Element> elements = finder.evaluate();
      // Return an arbitrary non-null object once the item is no longer found
      // to short-circuit `pumpUntil`.
      return elements.isEmpty ? Object() : null;
    },
  );
}

Future<BuildContext> findAndBookmark(
  BuildContext context,
  WidgetTester tester,
  TranslationMode mode,
  String headword,
) async {
  DictionaryModel.instance.currTranslationModel.searchModel.entrySearchModel
      .onSearchStringChanged(
    context: context,
    newSearchString: headword,
  );
  final Element element =
      await pumpUntilFound(tester, find.byHeadword(headword));
  final Entry entry = (element.widget as EntryViewPreview).entry;
  await DictionaryApp.db.setBookmark(TranslationMode.Spanish, entry, true);
  return element;
}
