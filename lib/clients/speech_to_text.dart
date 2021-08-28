import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:rogers_dictionary/models/translation_model.dart';

class SpeechToText {
  VoidCallback? _onListen;

  set onListen(VoidCallback newValue) => _onListen = newValue;

  static const String _fallbackSpanishLanguageId = 'es_MX';

  static final StreamController<String> statusStreamController =
      StreamController();
  static final Stream<String> statusStream =
      statusStreamController.stream.asBroadcastStream();
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static final Future<bool> _available = _speech.initialize(
    onError: (error) {
      print('Error initializing speech stream: $error');
    },
    onStatus: (status) {
      statusStreamController.add(status);
    },
  );

  late final Future<String> _spanishLanguageId = _speech.locales().then(
    (locales) {
      final List<String> ids = locales.map((l) => l.localeId).toList();
      return _speech.systemLocale().then<String>((systemLocale) {
        if (systemLocale != null && ids.contains(systemLocale.localeId)) {
          return systemLocale.localeId;
        }
        if (ids.contains(_fallbackSpanishLanguageId)) {
          return _fallbackSpanishLanguageId;
        }
        return ids.firstWhere((id) => id.startsWith('en'));
      });
    },
  );
  final String _englishLanguageId = 'en_US';

  Stream<RecordingUpdate> listenForText(TranslationMode mode) async* {
    _onListen?.call();
    final StreamController<RecordingUpdate> output = StreamController();
    final bool available = await _available;
    if (available) {
      RecordingUpdate currRecordingUpdate = const RecordingUpdate('', false, 0);
      late final StreamSubscription onDone;
      onDone = statusStream.listen((status) async {
        if (status == 'done') {
          await onDone.cancel();
          await output.close();
        }
      });
      await _speech.listen(
        pauseFor: const Duration(seconds: 2),
        listenMode: stt.ListenMode.search,
        localeId: await _getLocaleId(mode),
        onResult: (result) {
          print(result.alternates);
          currRecordingUpdate = currRecordingUpdate.copyWith(
            text: result.recognizedWords,
            isFinal: result.finalResult,
          );
          output.add(currRecordingUpdate);
          if (result.finalResult) {
            onDone.cancel();
            output.close();
          }
        },
        onSoundLevelChange: (soundLevel) {
          currRecordingUpdate = currRecordingUpdate.copyWith(
            soundLevel: soundLevel,
          );
          output.add(currRecordingUpdate);
        },
        cancelOnError: true,
      );
      yield* output.stream;
    } else {
      print('The user has denied the use of speech recognition.');
    }
  }

  Future<void> stop() {
    return _speech.stop();
  }

  Future<String> _getLocaleId(TranslationMode mode) async {
    if (isEnglish(mode)) {
      return _englishLanguageId;
    }
    return _spanishLanguageId;
  }
}

class RecordingUpdate {
  const RecordingUpdate(this.text, this.isFinal, this.soundLevel);

  final String text;
  final bool isFinal;
  final double soundLevel;

  RecordingUpdate copyWith({String? text, bool? isFinal, double? soundLevel}) {
    return RecordingUpdate(
      text ?? this.text,
      isFinal ?? this.isFinal,
      soundLevel ?? this.soundLevel,
    );
  }

  @override
  String toString() {
    return '$text, $isFinal, $soundLevel';
  }
}
