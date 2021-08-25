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
import 'package:provider/provider.dart';

import 'package:rogers_dictionary/clients/sqflite_database.dart';
import 'package:rogers_dictionary/clients/text_to_speech.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';
import 'package:rogers_dictionary/pages/dictionary_page.dart';
import 'package:rogers_dictionary/widgets/get_dictionary_feedback.dart';

import 'clients/dictionary_database.dart';
import 'models/dictionary_model.dart';

final Color englishPrimary = Colors.indigo.shade600;
final Color spanishPrimary = Colors.orange.shade600;
final Color englishSecondary = Colors.indigo.shade200;
final Color spanishSecondary = Colors.orange.shade200;

Color primaryColor(TranslationMode translationMode) =>
    isEnglish(translationMode)
        ? englishPrimary
        : spanishPrimary;

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

      runApp(MyApp());
    },
    FirebaseCrashlytics.instance.recordError,
  );
}

class MyApp extends StatefulWidget {
  static final DictionaryDatabase db = SqfliteDatabase();
  static final TextToSpeech textToSpeech = TextToSpeech();
  static final Future<PackageInfo> packageInfo = PackageInfo.fromPlatform();

  static final FirebaseAnalytics analytics = FirebaseAnalytics();

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    MyApp.textToSpeech.dispose();
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
          title: 'Dictionary',
          home: Provider<DictionaryModel>(
            create: (_) => DictionaryModel(),
            builder: (BuildContext context, _) {
              return DictionaryPage();
            },
          ),
          theme: ThemeData(
            selectedRowColor: Colors.grey.shade200,
            textTheme: TextTheme(
              headline1: GoogleFonts.roboto(
                fontSize: 36,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              headline2: GoogleFonts.roboto(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              bodyText2: GoogleFonts.roboto(
                fontSize: 22,
                fontWeight: FontWeight.normal,
              ),
            ),
            iconTheme: const IconThemeData(
              color: Colors.white,
              size: 28,
            ),
            accentIconTheme: const IconThemeData(
              size: 28,
              color: Colors.black45,
            ),
            backgroundColor: Colors.white,
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
