import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pedantic/pedantic.dart';

import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';

class PronunciationButton extends StatelessWidget {
  PronunciationButton({
    Key? key,
    required this.text,
    required this.mode,
  }) : super(key: key);

  final String text;
  final TranslationMode mode;

  final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPlaying,
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
              : _PlayButton(text, mode, _isPlaying, key: _buttonKey),
        );
      },
    );
  }

  double get _size =>
      (_buttonKey.currentContext!.findRenderObject() as RenderBox).size.height;
}

class _PlayButton extends StatelessWidget {
  const _PlayButton(
    this.text,
    this.mode,
    this._isPlaying, {
    Key? key,
  }) : super(key: key);

  final String text;
  final TranslationMode mode;
  final ValueNotifier<bool> _isPlaying;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        unawaited(MyApp.analytics.logEvent(
          name: 'play_audio',
          parameters: {
            'text': text,
            'mode': mode.toString().split('.').last,
          },
        ));
        _isPlaying.value = true;
        await MyApp.textToSpeech.playAudio(text, mode);
        _isPlaying.value = false;
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
