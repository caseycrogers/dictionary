import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/clients/speech_to_text.dart';

import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';

// Needs to be stateful so that the _currRecordingStream won't get trampled on
// rebuild.
class RecordButton extends StatefulWidget {
  const RecordButton({
    Key? key,
    required this.outputStreamController,
    required this.mode,
  }) : super(key: key);

  final StreamController<String> outputStreamController;
  final TranslationMode mode;

  @override
  _RecordButtonState createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  final ValueNotifier<Stream<RecordingUpdate>?> _currRecordingStream =
      ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Stream<RecordingUpdate>?>(
      valueListenable: _currRecordingStream,
      builder: (context, recordingStream, child) {
        if (recordingStream == null) {
          return IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () async {
              final Stream<RecordingUpdate> textStream =
                  DictionaryApp.speechToText(context).listenForText(widget.mode);
              _currRecordingStream.value = textStream;
              await widget.outputStreamController.addStream(
                textStream.map((result) => result.text),
              ).onError((error, stackTrace) => print(error));
              print('done!');
              _currRecordingStream.value = null;
            },
          );
        }
        return IconButton(
          onPressed: () {
            DictionaryApp.speechToText(context).stop();
            _currRecordingStream.value = null;
          },
          icon: const Icon(Icons.stop),
        );
      },
    );
  }
}
