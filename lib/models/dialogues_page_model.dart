// Dart imports:
import 'dart:collection';

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:rogers_dictionary/clients/dialogue_builders.dart';
import 'package:rogers_dictionary/dictionary_app.dart';
import 'package:rogers_dictionary/protobufs/dialogues.pb.dart';

class DialoguesPageModel {
  DialoguesPageModel() {
    _initializeStream();
  }

  // Only used for taking screenshots.
  void reset() {
    _dialogueStream = null;
    _dialogues.clear();
    _initializeStream();
    selectedSubChapter = null;
    selectedChapterNotifier.value = null;
  }

  // All static because these can be shared across both translation modes.
  static final LinkedHashSet<DialogueChapter> _dialogues = LinkedHashSet();
  static Stream<DialogueChapter>? _dialogueStream;

  final ValueNotifier<DialogueChapter?> selectedChapterNotifier = ValueNotifier<
      DialogueChapter?>(
    null,
  );

  DialogueChapter? get selectedChapter => selectedChapterNotifier.value;

  set selectedChapter(DialogueChapter? value) =>
      selectedChapterNotifier.value = value;

  DialogueSubChapter? selectedSubChapter;

  List<DialogueChapter> get dialogues => _dialogues.toList(growable: false);

  Stream<DialogueChapter> get dialogueStream => _dialogueStream!;

  static void _initializeStream() {
    if (_dialogueStream != null) {
      return;
    }
    Stream<DialogueChapter> stream;
    stream = DictionaryApp.db.getDialogues(startAt: _dialogues.length);
    _dialogueStream = stream.handleError((Object error, StackTrace stackTrace) {
      print('ERROR (dialogue stream): $error\n$stackTrace');
    }).map((DialogueChapter chapter) {
      if (!_dialogues.add(chapter))
        print('WARNING: added duplicate chapter ${chapter.englishTitle}. '
            'Set:\n${_dialogues.toList()}');
      return chapter;
    }).asBroadcastStream();
  }

  void onChapterSelected(BuildContext context, DialogueChapter? newChapter,
      DialogueSubChapter? newSubChapter) {
    selectedChapter = newChapter;
    selectedSubChapter = newSubChapter;
  }

  bool get hasSelection => selectedChapter != null;
}
