import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/clients/speech_to_text.dart';
import 'package:rogers_dictionary/models/translation_model.dart';

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
                DictionaryApp.speechToText(context).listenForText(widget.mode),
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
        return IconButton(
          onPressed: () {
            DictionaryApp.speechToText(context).stop();
            currSpeechStream.value = null;
          },
          icon: const Icon(Icons.stop),
        );
      },
    );
  }
}
