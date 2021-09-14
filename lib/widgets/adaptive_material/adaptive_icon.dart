import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'adaptive_material.dart';

class AdaptiveIcon extends StatelessWidget {
  const AdaptiveIcon(
    this.icon, {
    Key? key,
    this.forcePrimary = false,
    this.size,
    this.semanticLabel,
    this.textDirection,
  }) : super(key: key);

  final bool forcePrimary;
  final IconData icon;
  final double? size;
  final String? semanticLabel;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final Color? onColor = forcePrimary
        ? AdaptiveMaterial.onColorOf(context)
        : AdaptiveMaterial.secondaryOnColorOf(context);
    assert(
      onColor != null,
      'The current `context` did not contain a parent `AdaptiveColor`. To use '
      'and adaptive widget, place an `AdaptiveColor` widget above this one '
      'in the widget tree.',
    );
    return Icon(
      icon,
      color: onColor,
      size: size,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}
