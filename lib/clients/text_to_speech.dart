import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'package:audio_session/audio_session.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:rogers_dictionary/models/translation_model.dart';

final Uri _textToSpeechUrl =
    Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize');

const String _enCode = 'en-us';
const String _esCode = 'es-us';

const String _enName = 'en-US-Wavenet-B';
const String _esName = 'es-US-Wavenet-B';

const String _audioContent = 'audioContent';

const String _apiKeyFile = 'text_to_speech.key';

class TextToSpeech {
  TextToSpeech();

  final http.Client _client = http.Client();
  final AudioPlayer _player = AudioPlayer();
  final Future<AudioSession> _session = AudioSession.instance.then((session) {
    session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.voicePrompt,
        androidWillPauseWhenDucked: true,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.assistant,
        ),
      ),
    );
    return session;
  });

  static late final Future<String> _apiKey =
      rootBundle.loadString(join('assets', '$_apiKeyFile'));

  Stream<PlaybackInfo> playAudio(
    String text,
    TranslationMode mode,
  ) async* {
    final Directory tmpDir = await getTemporaryDirectory();
    final File mp3 = File(
      join(
        tmpDir.path,
        _textToFileName(text, mode),
      ),
    );
    await mp3.parent.create();
    if (!mp3.existsSync()) {
      await mp3.writeAsBytes(await _getMp3(text, mode));
    }
    await _session;
    final ProgressiveAudioSource source = ProgressiveAudioSource(mp3.uri);
    await _player.setAudioSource(source);
    await _player.play();

    yield* _getStream(text, mode);
  }

  bool isPlaying(String text, TranslationMode mode) {
    return _textToFileName(text, mode) ==
        (_player.audioSource as ProgressiveAudioSource).uri.pathSegments.last;
  }

  Future<void> stopIfPlaying(String text, TranslationMode mode) async {
    if (isPlaying(text, mode)) {
      // Only stop if we're the currently playing this text.
      return stop();
    }
  }

  Future<void> stop() async {
    if (_player.duration != null) {
      await _player.seek(
        // We seek instead of stop as a garbage hack to ensure that the stream
        // finishes.
        Duration(milliseconds: _player.duration!.inMilliseconds + 1),
      );
    }
  }

  void dispose() {
    _client.close();
    _player.dispose();
  }

  Stream<PlaybackInfo> _getStream(String text, TranslationMode mode) async* {
    // Ensure duration is initialized before we emit events.
    final Duration duration = (await _player.durationFuture)!;
    PlaybackInfo _currentPlaybackInfo() {
      return PlaybackInfo(
        track: text,
        state: _player.processingState,
        // Position can overshoot-clamp it if it does.
        position: _player.position > duration ? duration : _player.position,
        duration: duration,
      );
    }

    // We need to emit from both streams to ensure we get all events from both.
    final StreamController<PlaybackInfo> controller = StreamController();
    final StreamSubscription positionSub = _player.positionStream.listen(
      (_) {
        controller.add(_currentPlaybackInfo());
      },
    );
    final StreamSubscription stateSub = _player.processingStateStream.listen(
      (_) {
        controller.add(_currentPlaybackInfo());
      },
    );
    yield* controller.stream.map(
      (info) {
        if (info.isDone || !isPlaying(text, mode)) {
          // Clean up when a complete info object is received or another audio
          // source starts playing.
          positionSub.cancel();
          stateSub.cancel();
          controller.close();
        }
        return info;
      },
    );
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

  String _textToFileName(String text, TranslationMode mode) {
    return '${mode.toString().replaceAll('.', '_')}'
        '_${text.replaceAll(' ', '_')}.mp3';
  }
}

class PlaybackInfo {
  const PlaybackInfo({
    required this.track,
    required this.state,
    required this.position,
    required this.duration,
  });

  factory PlaybackInfo.initialPosition(String track) {
    return PlaybackInfo(
      track: track,
      state: ProcessingState.loading,
      position: Duration.zero,
      duration: Duration.zero,
    );
  }

  final String track;
  final ProcessingState state;
  final Duration position;
  final Duration duration;

  bool get isDone => position == duration && state == ProcessingState.completed;

  @override
  String toString() {
    return '$state: ${position.inMilliseconds}/${duration.inMilliseconds} '
        '-- $track';
  }
}
