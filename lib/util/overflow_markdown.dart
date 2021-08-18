import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/util/overflow_markdown_base.dart';

class OverflowMarkdown extends StatelessWidget {
  OverflowMarkdown(
    this.text, {
    this.overflow,
    this.defaultStyle,
    this.overrideRules,
    this.overrideStyles,
  })  : assert(overrideRules?.length == overrideStyles?.length),
        base = MarkdownBase(
          text,
          overrideRules,
        );

  final String text;
  final TextOverflow? overflow;
  final TextStyle? defaultStyle;
  final List<OverrideRule>? overrideRules;
  final List<TextStyle>? overrideStyles;
  final MarkdownBase base;

  List<Widget> forWrap(BuildContext context) {
    final List<TextSpan> spans = [];
    base.constructSpans().forEach(
      (entry) {
        final s = entry.value;
        final textStyle = getTextStyle(context, entry.key);
        if (!entry.key.canWrap) {
          spans.add(TextSpan(text: s, style: textStyle));
          return;
        }
        if (entry.key.isSubscript && spans.isNotEmpty) {
          // Subscript should not be wrapped
          spans[spans.length - 1] = TextSpan(
              children: [spans.last, TextSpan(text: s, style: textStyle)]);
          return;
        }
        spans.addAll(
          s.split(' ').map(
                (word) => TextSpan(
                  // Add space back in for all but last word
                  text: word == s.split(' ').last ? word : '$word ',
                  style: textStyle,
                ),
              ),
        );
      },
    );
    return spans.map((s) => _constructText(context, [s])).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _constructText(
      context,
      base
          .constructSpans()
          .map((e) =>
              TextSpan(text: e.value, style: getTextStyle(context, e.key)))
          .toList(),
    );
  }

  Widget _constructText(BuildContext context, List<TextSpan> spans) {
    return RichText(
      overflow: overflow ?? TextOverflow.visible,
      text: TextSpan(
        style: defaultStyle ?? Theme.of(context).textTheme.bodyText2,
        children: spans,
      ),
    );
  }

  TextStyle getTextStyle(BuildContext context, MarkdownStyle mdStyle) {
    final TextStyle baseStyle =
        defaultStyle ?? Theme.of(context).textTheme.bodyText2!;
    if (mdStyle.isDefault) {
      return baseStyle;
    }
    return baseStyle
        .merge(mdStyle.overrideStyle == null
            ? null
            : overrideStyles?[mdStyle.overrideStyle!].copyWith(inherit: true))
        .copyWith(
          fontWeight: mdStyle.isBold ? FontWeight.bold : null,
          fontStyle: mdStyle.isItalic ? FontStyle.italic : null,
          fontSize: mdStyle.isSubscript ? baseStyle.fontSize! / 2 : null,
        );
  }
}
