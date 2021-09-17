import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:rogers_dictionary/models/translation_model.dart';

import 'dictionary_app.dart';

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
  if (!(Platform.isAndroid || Platform.isIOS)) {
    return runApp(DictionaryApp());
  }
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
