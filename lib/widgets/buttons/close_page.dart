import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rogers_dictionary/widgets/adaptive_material/adaptive_icon_button.dart';

class ClosePage extends StatelessWidget {
  const ClosePage({Key? key, required this.onClose})
      : super(key: key);

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AdaptiveIconButton(
      icon: Icon(
        Icons.close,
      ),
      onPressed: onClose,
    );
  }
}
