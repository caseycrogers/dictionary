import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveIcon extends StatelessWidget {
  const AdaptiveIcon(
    this.icon, {
    Key? key,
    this.size,
    this.semanticLabel,
    this.textDirection,
  }) : super(key: key);

  final IconData icon;
  final double? size;
  final String? semanticLabel;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}
