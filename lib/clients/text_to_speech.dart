import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:rogers_dictionary/models/translation_page_model.dart';

final Uri _textToSpeechUrl =
    Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize');

const String _enCode = 'en-us';
const String _esCode = 'es-us';

const String _enName = 'en-US-Wavenet-B';
const String _esName = 'es-US-Wavenet-B';

const String _audioContent = 'audioContent';

const String _apiKeyFile = 'text_to_speech.key';

class TextToSpeech {
  final http.Client _client = http.Client();
  final AudioPlayer _audioPlayer = AudioPlayer();

  static late final Future<String> _apiKey =
      rootBundle.loadString(join('assets', '$_apiKeyFile'));

  Future<void> playAudio(String text, TranslationMode mode) async {
    final Directory tmpDir = await getTemporaryDirectory();
    final File mp3 = File(
      join(
        tmpDir.path,
        mode.toString().replaceAll('.', '_'),
        '${text.replaceAll(' ', '_')}.mp3',
      ),
    );
    await mp3.parent.create();
    if (!mp3.existsSync()) {
      await mp3.writeAsBytes(await _getMp3(text, mode));
    }
    // Stop any other audio files that are currently playing.
    if (_audioPlayer.state == PlayerState.PLAYING) {
      await _audioPlayer.stop();
    }

    // Ensure we create this before playing so we don't miss the event.
    final Future<void> done = _onPlayerStoppedOrCompleted;
    await _audioPlayer.play(
      mp3.path,
      isLocal: true,
    );
    await done;
  }

  void dispose() {
    _client.close();
    _audioPlayer.stop();
    _audioPlayer.release();
  }

  String _data(String text, TranslationMode mode) {
    return json.encode(
      {
        'input': {
          'text': text,
        },
        'voice': {
          'languageCode': isEnglish(mode) ? _enCode : _esCode,
          'name': isEnglish(mode) ? _enName : _esName,
          'ssmlGender': 'MALE'
        },
        'audioConfig': {'audioEncoding': 'MP3'}
      },
    );
  }

  Uint8List _extractAudio(http.Response response) {
    return base64Decode(
      (json.decode(response.body) as Map<String, Object?>)[_audioContent]
          as String,
    );
  }

  Future<void> get _onPlayerStoppedOrCompleted {
    return _audioPlayer.onPlayerCompletion.firstWhere(
      (_) {
        return [PlayerState.COMPLETED, PlayerState.STOPPED]
            .contains(_audioPlayer.state);
      },
    );
  }

  Future<Uint8List> _getMp3(String text, TranslationMode mode) async {
    final http.Response response = await http.post(
      _textToSpeechUrl,
      headers: {
        'Authorization': '',
        'Content-Type': 'application/json; charset=utf-8',
        'X-Goog-Api-Key': await _apiKey,
      },
      body: _data(text, mode),
    );
    return _extractAudio(response);
  }
}
