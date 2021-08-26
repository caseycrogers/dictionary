import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pedantic/pedantic.dart';

import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';

class RecordButton extends StatelessWidget {
  RecordButton({
    Key? key,
    required this.outputStream,
    required this.mode,
  }) : super(key: key);

  final StreamController<String> outputStream;
  final TranslationMode mode;

  final ValueNotifier<bool> _isRecording = ValueNotifier<bool>(false);
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isRecording,
      builder: (context, isPlaying, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              child: child,
              opacity: animation,
            );
          },
          child: isPlaying
              ? _ProgressIndicator(_size)
              : _RecordButton(
                  outputStream,
                  mode,
                  _isRecording,
                  key: _buttonKey,
                ),
        );
      },
    );
  }

  double get _size =>
      (_buttonKey.currentContext!.findRenderObject() as RenderBox).size.height;
}

class _RecordButton extends StatelessWidget {
  const _RecordButton(
    this.outPutStream,
    this.mode,
    this._isRecording, {
    Key? key,
  }) : super(key: key);

  final StreamController<String> outPutStream;
  final TranslationMode mode;
  final ValueNotifier<bool> _isRecording;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        unawaited(MyApp.analytics.logEvent(
          name: 'play_audio',
          parameters: {
            'text': 'asdf',
            'mode': mode.toString().split('.').last,
          },
        ));
        _isRecording.value = true;
        await MyApp.textToSpeech.playAudio('asdf', mode);
        _isRecording.value = false;
      },
      icon: Icon(
        Icons.volume_up,
        color: Theme.of(context).accentIconTheme.color,
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator(this.size, {Key? key}) : super(key: key);

  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        height: size,
        width: size,
        padding: const EdgeInsets.all(12),
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Theme.of(context).accentIconTheme.color,
        ),
      ),
    );
  }
}
