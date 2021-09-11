import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/models/search_model.dart';
import 'package:rogers_dictionary/util/change_notifier_extension.dart';
import 'package:rogers_dictionary/util/constants.dart';

class CollapsingNoResultsWidget extends StatelessWidget {
  const CollapsingNoResultsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _CollapsingScrollEntry(child: NoResultsWidget());
  }
}

class NoResultsWidget extends StatelessWidget {
  const NoResultsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SearchModel searchPageModel = SearchModel.of(context);
    final String searchHint =
        searchPageModel.entrySearchModel.searchString.isEmpty
            ? i18n.enterTextHint.get(context)
            : i18n.typosHint.get(context);

    return IconTheme.merge(
      data: const IconThemeData(
        color: Colors.grey,
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2 * kPad),
          child: Column(
            children: [
              Text(
                searchPageModel.entrySearchModel.isBookmarkedOnly
                    ? i18n.noBookmarksHint.get(context)
                    : searchHint,
              ),
              Text(
                searchPageModel.isEnglish
                    ? i18n.swipeForSpanish.get(context)
                    : i18n.swipeForEnglish.get(context),
              ),
              const Icon(Icons.swipe),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsingScrollEntry extends StatefulWidget {
  const _CollapsingScrollEntry({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _CollapsingScrollEntryState createState() => _CollapsingScrollEntryState();
}

class _CollapsingScrollEntryState extends State<_CollapsingScrollEntry> {
  late ScrollPosition _position;

  bool _shouldInit = true;
  double? _height;
  double _pixels = 0;

  double get _progress =>
      _height == null ? 0 : (_pixels / _height!).clamp(0, 1);

  void _onScroll() {
    _height ??= (context.findRenderObject() as RenderBox).size.height;
    _pixels = _position.pixels;
    // This widget will already be disposed if progress exceeds 1.
    if (_progress < 1) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    if (_shouldInit || _position.isDisposed) {
      _position = Scrollable.of(context)!.position;
      _position.addListener(_onScroll);
      _shouldInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (!_position.isDisposed) {
      _position.removeListener(_onScroll);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: _progress > 0 ? Clip.hardEdge : Clip.none,
      decoration: const BoxDecoration(),
      child: Opacity(
        opacity: 1 - _progress,
        child: Transform.translate(
          offset: Offset(0, _pixels / 2),
          child: widget.child,
        ),
      ),
    );
  }
}
