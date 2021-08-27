import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:rogers_dictionary/models/translation_model.dart';

class SpeechToText {
  SpeechToText(this.systemLanguageId);

  final String systemLanguageId;
  static const String _fallbackSpanishLanguageId = 'es_US';

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
    final Future<void> isClosed = statusStream
        .firstWhere((status) => status == 'done')
        .whenComplete(() => output.close());
    final bool available = await _available;
    if (available) {
      RecordingUpdate currRecordingUpdate = const RecordingUpdate('', false, 0);
      yield currRecordingUpdate;
      await _speech.listen(
        pauseFor: const Duration(seconds: 2),
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
