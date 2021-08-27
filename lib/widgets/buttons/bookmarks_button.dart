import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/main.dart';
import 'package:rogers_dictionary/models/translation_page_model.dart';
import 'package:rogers_dictionary/protobufs/entry.pb.dart';

class BookmarksButton extends StatefulWidget {
  const BookmarksButton({required this.entry});

  final Entry entry;

  @override
  _BookmarksButtonState createState() => _BookmarksButtonState();
}

class _BookmarksButtonState extends State<BookmarksButton> {
  @override
  Widget build(BuildContext context) {
    final translationMode = TranslationPageModel.of(context).translationMode;
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: _icon,
      onPressed: () async {
        final bool newIsBookmarked = !DictionaryApp.db.isBookmarked(
            translationMode, widget.entry.headword.urlEncodedHeadword);
        await DictionaryApp.analytics.logEvent(
          name: 'set_bookmark',
          parameters: {
            'entry': widget.entry.headword.urlEncodedHeadword,
            'value': newIsBookmarked.toString(),
          },
        );
        await DictionaryApp.db.setBookmark(
          translationMode,
          widget.entry.headword.urlEncodedHeadword,
          newIsBookmarked,
        );
        setState(() {});
      },
    );
  }

  Widget get _icon {
    return Icon(
      DictionaryApp.db.isBookmarked(TranslationPageModel.of(context).translationMode,
              widget.entry.headword.urlEncodedHeadword)
          ? Icons.bookmark
          : Icons.bookmark_border,
      color: Theme.of(context).accentIconTheme.color,
      size: Theme.of(context).accentIconTheme.size,
    );
  }
}
