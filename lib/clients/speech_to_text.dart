import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:rogers_dictionary/models/translation_page_model.dart';

class SpeechToText {
  SpeechToText(this.systemLanguageId);

  final String systemLanguageId;
  static const String _fallbackSpanishLanguageId = 'es_US';

  final stt.SpeechToText speech = stt.SpeechToText();

  late final Future<String> _spanishLanguageId = speech.locales().then(
    (locales) {
      final List<String> ids = locales.map((l) => l.localeId).toList();
      if (ids.contains(systemLanguageId)) {
        return systemLanguageId;
      }
      if (ids.contains(_fallbackSpanishLanguageId)) {
        return _fallbackSpanishLanguageId;
      }
      return ids.firstWhere((id) => id.startsWith('en'));
    },
  );
  final String _englishLanguageId = 'en_US';

  Stream<RecordingUpdate> listenForText(TranslationMode mode) async* {
    final StreamController<RecordingUpdate> output = StreamController();
    final bool available = await speech.initialize(
      onError: (error) {
        print('asdf: $error');
      },
      onStatus: (status) {
        if (status == 'done') {
          output.close();
        }
      },
    );
    if (available) {
      RecordingUpdate currRecordingUpdate = const RecordingUpdate('', false, 0);
      await speech.listen(
        pauseFor: const Duration(seconds: 3),
        listenMode: stt.ListenMode.search,
        localeId: await _getLocaleId(mode),
        onResult: (result) {
          currRecordingUpdate = currRecordingUpdate.copyWith(
            text: result.recognizedWords,
            isFinal: result.finalResult,
          );
          output.add(currRecordingUpdate);
          if (result.finalResult) {
            // No more words, finish.
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
    return speech.stop();
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
