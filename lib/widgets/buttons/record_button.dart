import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/clients/speech_to_text.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/util/dictionary_progress_indicator.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({
    Key? key,
    required this.mode,
  }) : super(key: key);

  final TranslationMode mode;

  @override
  _RecordButtonState createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  final StreamController<double> soundLevelController = StreamController();
  late final Stream<double> soundLevelStream =
      soundLevelController.stream.asBroadcastStream();

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<Stream<RecordingUpdate>?> currSpeechStream =
        DictionaryModel.of(context)
            .currTranslationModel
            .searchPageModel
            .entrySearchModel
            .currSpeechToTextStream;
    return ValueListenableBuilder<Stream<RecordingUpdate>?>(
      valueListenable: currSpeechStream,
      builder: (context, recordingStream, child) {
        if (recordingStream == null) {
          return IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () async {
              final StreamController<RecordingUpdate> output =
                  StreamController();
              currSpeechStream.value = output.stream;
              // Use a controller here so we can know when it's done and clean
              // up here.
              await output
                  .addStream(
                DictionaryApp.speechToText
                    .listenForText(widget.mode)
                    .map((update) {
                  soundLevelController.add(update.soundLevel);
                  return update;
                }),
              )
                  .onError(
                (error, stackTrace) {
                  print('ERROR (speech stream): $error, $stackTrace');
                },
              );
              await output.close();
              currSpeechStream.value = null;
            },
          );
        }
        double prevPrevLevel = 0;
        double prevLevel = 0;
        return StreamBuilder<double>(
          stream: soundLevelStream,
          initialData: 0,
          builder: (context, snap) {
            final double rollingAvg =
                (snap.data! + prevPrevLevel + prevLevel) / 3;
            // Original ranges from -2 to 10.
            final double scale = ((rollingAvg + 2) / 16).clamp(0, 1) + .2;
            prevPrevLevel = prevLevel;
            prevLevel = snap.data!;
            return ProgressGradient(
              progress: scale.clamp(0, 1),
              style: IndicatorStyle.radial,
              child: IconButton(
                onPressed: () {
                  DictionaryApp.speechToText.stop();
                  currSpeechStream.value = null;
                },
                icon: const Icon(Icons.stop),
              ),
              positiveColor: Colors.white30,
              negativeColor: Colors.transparent,
            );
          },
        );
      },
    );
  }
}
