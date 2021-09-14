import 'dart:async';

import 'package:feedback/feedback.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info/package_info.dart';
import 'package:rogers_dictionary/clients/dictionary_database/dictionary_database.dart';

import 'package:rogers_dictionary/clients/dictionary_database/sqflite_database.dart';
import 'package:rogers_dictionary/clients/text_to_speech.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/pages/dictionary_page.dart';
import 'package:rogers_dictionary/util/resolution_tester.dart';
import 'package:rogers_dictionary/widgets/get_dictionary_feedback.dart';

final ColorScheme englishColorScheme = ColorScheme.fromSwatch(
  primarySwatch: Colors.indigo,
  backgroundColor: Colors.grey.shade200,

);

final ColorScheme spanishColorScheme = ColorScheme.fromSwatch(
  primarySwatch: Colors.orange,
  backgroundColor: Colors.grey.shade200,
).copyWith(onPrimary: Colors.white);

ColorScheme themeOf(TranslationModel translationModel) {
  if (translationModel.isEnglish) {
    return englishColorScheme;
  }
  return spanishColorScheme;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();

  return runZonedGuarded<void>(
    () async {
      if (kDebugMode) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(false);
      }
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      runApp(DictionaryApp());
    },
    FirebaseCrashlytics.instance.recordError,
  );
}

class DictionaryApp extends StatefulWidget {
  // Client instances.
  static final DictionaryDatabase db = SqfliteDatabase();
  static final TextToSpeech textToSpeech = TextToSpeech();
  static final Future<PackageInfo> packageInfo = PackageInfo.fromPlatform();
  static final FirebaseAnalytics analytics = FirebaseAnalytics();

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  _DictionaryAppState createState() => _DictionaryAppState();

  static _DictionaryAppState of(BuildContext context) {
    return context.findAncestorStateOfType<_DictionaryAppState>()!;
  }
}

class _DictionaryAppState extends State<DictionaryApp> {
  @override
  void dispose() {
    DictionaryApp.textToSpeech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: BetterFeedback(
        mode: FeedbackMode.draw,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        feedbackBuilder: (BuildContext context, OnSubmit onSubmit) =>
            GetDictionaryFeedback(onSubmit),
        child: MaterialApp(
          title: 'Rogers Dictionary',
          home: DictionaryPage(),
          theme: ThemeData(
            selectedRowColor: Colors.grey.shade200,
            textTheme: TextTheme(
              headline1: GoogleFonts.roboto(
                fontSize: 30,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              headline2: GoogleFonts.roboto(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              bodyText2: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('es', ''),
          ],
        ),
      ),
    );
  }
}
