// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:rogers_dictionary/models/dictionary_model.dart';
import 'package:rogers_dictionary/util/entry_utils.dart';
import 'package:rogers_dictionary/widgets/adaptive_material.dart';
import 'package:rogers_dictionary/widgets/buttons/inline_icon_button.dart';

class OppositeHeadwordButton extends StatelessWidget {
  const OppositeHeadwordButton({
    Key? key,
    required this.translation,
  }) : super(key: key);

  final Translation translation;

  @override
  Widget build(BuildContext context) {
    return InlineIconButton(
      Icons.swap_horiz,
      onPressed: () {
        DictionaryModel.instance.onOppositeHeadwordSelected(
          context,
          translation.oppositeHeadword,
        );
      },
    );
  }
}

class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    Key? key,
    this.iconSize = 24.0,
    this.visualDensity,
    this.padding = const EdgeInsets.all(8),
    this.alignment = Alignment.center,
    this.splashRadius,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    required this.onPressed,
    this.mouseCursor = SystemMouseCursors.click,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback = true,
    this.constraints,
    required this.icon,
  }) : super(key: key);

  final double iconSize;
  final VisualDensity? visualDensity;
  final EdgeInsets padding;
  final Alignment alignment;
  final double? splashRadius;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final Color? disabledColor;
  final VoidCallback? onPressed;
  final MouseCursor mouseCursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? tooltip;
  final bool enableFeedback;
  final BoxConstraints? constraints;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final Color? onColor = AdaptiveMaterial.secondaryOnColorOf(context);
    assert(
      onColor != null,
      'The current `context` did not contain a parent `AdaptiveColor`. To use '
      'and adaptive widget, place an `AdaptiveColor` widget above this one '
      'in the widget tree.',
    );
    return IconButton(
      iconSize: iconSize,
      visualDensity: visualDensity,
      padding: padding,
      alignment: alignment,
      splashRadius: splashRadius,
      color: onColor,

      /// TODO(caseycrogers): These colors should reflect `onColor` too.
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      disabledColor: disabledColor,
      onPressed: onPressed,
      mouseCursor: mouseCursor,
      focusNode: focusNode,
      autofocus: autofocus,
      tooltip: tooltip,
      enableFeedback: enableFeedback,
      constraints: constraints,
      icon: icon,
    );
  }
}
