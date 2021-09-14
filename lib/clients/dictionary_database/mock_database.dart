import 'package:rogers_dictionary/clients/dictionary_database/dictionary_database.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/protobufs/dialogues.pb.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';

class MockDatabase extends DictionaryDatabase {
  @override
  Stream<DialogueChapter> getDialogues({required int startAt}) async* {
    yield DialogueChapter(
        chapterId: 1,
        englishTitle: 'foo',
        spanishTitle: 'foó',
        dialogueSubChapters: [
          DialogueChapter_SubChapter(
            englishTitle: 'bar',
            spanishTitle: 'bár',
          ),
        ]);
  }

  @override
  Stream<Entry> getEntries(
    TranslationMode translationMode, {
    required String searchString,
    required int startAt,
  }) {
    if (startAt != 0) {
      return const Stream.empty();
    }
    return getEntry(translationMode, 'foo').asStream();
  }

  @override
  Future<Entry> getEntry(
    TranslationMode translationMode,
    String urlEncodedHeadword,
  ) async {
    await super.setBookmark(translationMode, 'foo', true);
    return Entry(
      entryId: 0,
      headword: Entry_Headword(headwordText: 'foo'),
      translations: [Entry_Translation(content: 'bar')],
    );
  }
}
