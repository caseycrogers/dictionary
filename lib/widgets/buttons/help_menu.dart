import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/widgets/adaptive_material/adaptive_icon.dart';
import 'package:rogers_dictionary/widgets/buttons/about_button.dart';

import 'package:rogers_dictionary/widgets/buttons/drop_down_widget.dart';
import 'package:rogers_dictionary/widgets/buttons/feedback_button.dart';

class HelpMenu extends StatelessWidget {
  const HelpMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropDownWidget(
      builder: (_, closeMenu) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedbackButton(onPressed: closeMenu),
          AboutButton(onPressed: closeMenu),
        ],
      ),
      icon: const AdaptiveIcon(Icons.more_vert, forcePrimary: true),
    );
  }
}
