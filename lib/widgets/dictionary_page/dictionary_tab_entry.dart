import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  late TabController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = DefaultTabController.of(context)!;
    _controller.addListener(_onTabSelected);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabSelected);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>  Tab(
          icon: widget.icon,
          text: _controller.index == widget.index ? widget.text : null,
        );

  void _onTabSelected() {
    if (mounted) {
      setState(() {});
    }
  }
}
