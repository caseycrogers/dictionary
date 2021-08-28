import 'package:flutter/animation.dart';

class InstantOutCurve extends Curve {
  const InstantOutCurve({required this.atStart});

  // Whether the object should go out at the start or the end.
  final bool atStart;

  @override
  double transform(double t) {
    if (atStart || t == 1.0) {
      return 1;
    }
    return 0;
  }
}