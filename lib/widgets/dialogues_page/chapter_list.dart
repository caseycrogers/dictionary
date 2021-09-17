import 'package:async_list_view/async_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/clients/dialogue_builders.dart';
import 'package:rogers_dictionary/models/dialogues_page_model.dart';
import 'package:rogers_dictionary/models/translation_model.dart';
import 'package:rogers_dictionary/protobufs/dialogues.pb.dart';
import 'package:rogers_dictionary/util/dialogue_extensions.dart';
import 'package:rogers_dictionary/util/text_utils.dart';
import 'package:rogers_dictionary/widgets/adaptive_material/adaptive_material.dart';
import 'package:rogers_dictionary/widgets/buttons/indent_icon.dart';
import 'package:rogers_dictionary/widgets/loading_text.dart';

class ChapterList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TranslationModel dialoguesModel = TranslationModel.of(context);
    return AsyncListView<DialogueChapter>(
      key: const PageStorageKey('dialogues'),
      padding: EdgeInsets.zero,
      initialData: dialoguesModel.dialoguesPageModel.dialogues,
      stream: dialoguesModel.dialoguesPageModel.dialogueStream,
      itemBuilder: _buildTopic,
    );
  }

  Widget _buildTopic(BuildContext context,
          AsyncSnapshot<List<DialogueChapter>> snapshot, int index) =>
      Builder(
        builder: (BuildContext context) {
          if (snapshot.hasError) {
            print(snapshot.error);
          }
          if (!snapshot.hasData) {
            return const LoadingText();
          }
          final DialogueChapter chapter = snapshot.data![index];
          if (index != 0 &&
              chapter.title(context) ==
                  snapshot.data![index - 1].title(context)) {
            return Container();
          }
          if (chapter.hasSubChapters)
            return ExpansionTile(
              title: bold1Text(context, chapter.title(context)),
              subtitle: Text(
                chapter.oppositeTitle(context),
                style: TextStyle(color: Colors.grey.shade700),
              ),
              key: _getKey(context, chapter),
              children: chapter.dialogueSubChapters
                  .map(
                    (subChapter) => _clickableHeader(
                      context,
                      true,
                      chapter: chapter,
                      subChapter: subChapter,
                    ),
                  )
                  .toList(),
              iconColor: AdaptiveMaterial.secondaryOnColorOf(context),
            );
          return _clickableHeader(context, false, chapter: chapter);
        },
      );

  PageStorageKey _getKey(BuildContext context, DialogueChapter dialogue) =>
      PageStorageKey<String>(dialogue.englishTitle);

  Widget _clickableHeader(
    BuildContext context,
    bool isSubHeader, {
    required DialogueChapter chapter,
    DialogueSubChapter? subChapter,
  }) {
    final DialoguesPageModel dialoguesModel =
        TranslationModel.of(context).dialoguesPageModel;
    return ListTile(
      minLeadingWidth: 0,
      leading: isSubHeader ? const IndentIcon() : null,
      title: bold1Text(
        context,
        subChapter?.title(context) ?? chapter.title(context),
      ),
      subtitle: Text(
          subChapter?.oppositeTitle(context) ?? chapter.oppositeTitle(context)),
      onTap: () =>
          dialoguesModel.onChapterSelected(context, chapter, subChapter),
    );
  }
}
