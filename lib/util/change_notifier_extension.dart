import 'package:flutter/cupertino.dart';

extension ChangeNotifierExtension on ChangeNotifier {
  bool get isDisposed {
    try {
      hasListeners;
    } on AssertionError {
      return true;
    }
    return false;
  }
}
