import 'package:flutter/material.dart';
import 'package:rogers_dictionary/util/constants.dart';

import 'package:rogers_dictionary/widgets/adaptive_material.dart';

class InlineIconButton extends StatelessWidget {
  const InlineIconButton(this.icon, {
    Key? key,
    required this.onPressed,
    this.color,
    this.size,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(size ?? IconTheme
          .of(context)
          .size! / 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: kPad/2),
        child: AdaptiveIcon(
          icon,
          size: size ?? IconTheme
              .of(context)
              .size!,
          color: color,
        ),
      ),
      onTap: onPressed,
    );
  }
}