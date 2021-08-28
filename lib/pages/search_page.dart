import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rogers_dictionary/widgets/search_page/search_page_layout.dart';

class SearchPage extends StatelessWidget {
  static const String route = 'search';

  static bool matchesUri(Uri uri) => uri.pathSegments.contains(route);

  @override
  Widget build(BuildContext context) {
    return const _UnFocusOnDrag(
      child: SearchPageLayout(),
    );
  }
}

class _UnFocusOnDrag extends StatelessWidget {
  const _UnFocusOnDrag({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      child: child,
      onNotification: (ScrollUpdateNotification notification) {
        final FocusScopeNode focusNode = FocusScope.of(context);
        if (notification.dragDetails != null && focusNode.hasFocus) {
          focusNode.unfocus();
        }
        return false;
      },
    );
  }
}
