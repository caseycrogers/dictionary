import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DictionaryProgressIndicator extends StatelessWidget {
  const DictionaryProgressIndicator({
    Key? key,
    required this.child,
    required this.style,
    required this.progress,
  }) : super(key: key);

  final Widget child;
  final IndicatorStyle style;
  final ValueListenable<double> progress;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (context, progress, _) {
        return ProgressGradient(
          child: child,
          style: style,
          progress: progress,
        );
      },
    );
  }
}

class ProgressGradient extends StatelessWidget {
  const ProgressGradient({
    Key? key,
    required this.child,
    required this.style,
    required this.progress,
    this.positiveColor,
    this.negativeColor
  }) : super(key: key);

  final Widget child;
  final IndicatorStyle style;
  final double progress;
  final Color? positiveColor;
  final Color? negativeColor;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case IndicatorStyle.linear:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                positiveColor ?? Theme.of(context).selectedRowColor,
                negativeColor ?? Theme.of(context).cardColor,
              ],
              stops: [
                progress,
                progress,
              ],
            ),
          ),
          child: child,
        );
      case IndicatorStyle.circular:
        return Transform.rotate(
          angle: -math.pi / 2,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  positiveColor ?? Theme.of(context).selectedRowColor,
                  negativeColor ?? Theme.of(context).cardColor,
                ],
                stops: [
                  progress,
                  progress,
                ],
              ),
            ),
            child: child,
          ),
        );
      case IndicatorStyle.radial:
        return AnimatedContainer(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                positiveColor ?? Theme.of(context).selectedRowColor,
                negativeColor ?? Theme.of(context).cardColor,
              ],
              stops: [
                progress,
                progress,
              ],
            ),
          ),
          duration: const Duration(milliseconds: 10),
          child: child,
        );
    }
  }
}

enum IndicatorStyle {
  linear,
  radial,
  circular,
}