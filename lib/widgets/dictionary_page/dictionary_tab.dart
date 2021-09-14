import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;

enum DictionaryTab {
  search,
  bookmarks,
  dialogues,
}

DictionaryTab indexToTab(int index) {
  return DictionaryTab.values[index];
}

int tabToIndex(DictionaryTab tab) {
  return DictionaryTab.values.indexOf(tab);
}

IconData tabToIcon(DictionaryTab tab) {
  switch (tab) {
    case DictionaryTab.search:
      return Icons.search;
    case DictionaryTab.bookmarks:
      return Icons.bookmarks_outlined;
    case DictionaryTab.dialogues:
      return Icons.speaker_notes_outlined;
  }
}

String tabToText(BuildContext context, DictionaryTab tab) {
  switch (tab) {
    case DictionaryTab.search:
      return i18n.search.cap.get(context);
    case DictionaryTab.bookmarks:
      return i18n.bookmarks.cap.get(context);
    case DictionaryTab.dialogues:
      return i18n.dialogues.cap.get(context);
  }
}

class DictionaryTabEntry extends StatefulWidget {
  const DictionaryTabEntry({
    required this.icon,
    required this.text,
    required this.index,
  });

  final Widget icon;
  final String? text;
  final int index;

  @override
  _DictionaryTabEntryState createState() => _DictionaryTabEntryState();
}

class _DictionaryTabEntryState extends State<DictionaryTabEntry> {
  bool _isInitialized = false;
  late TabController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _controller = DefaultTabController.of(context)!;
      _controller.addListener(_onTabSelected);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabSelected);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tab(
      icon: widget.icon,
      text: _controller.index == widget.index ? widget.text : null,
    );
  }

  void _onTabSelected() {
    if (mounted) {
      setState(() {});
    }
  }
}
