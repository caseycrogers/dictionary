import 'package:flutter/cupertino.dart';

bool isBigEnoughForAdvanced(BuildContext context) {
  final MediaQueryData query = MediaQuery.of(context);
  if (query.size.width < 756) {
    return false;
  }
  return true;
}