import 'package:flutter/material.dart';

enum AdaptiveColor {
  primary,
  secondary,
  background,
  surface,
}

class AdaptiveMaterial extends StatelessWidget {
  const AdaptiveMaterial({
    required this.adaptiveColor,
    required this.child,
  });

  final AdaptiveColor adaptiveColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return _ColorProvider<_OnColor>(
      adaptiveColor,
      _ColorProvider<_Color>(
        adaptiveColor,
        Material(
          color: _toColor(context, adaptiveColor),
          child: child,
        ),
        _toColor(context, adaptiveColor)!,
      ),
      _toOnColor(context, adaptiveColor)!,
    );
  }

  static Color? colorOf(BuildContext context) {
    final _ColorProvider? result =
        context.dependOnInheritedWidgetOfExactType<_ColorProvider<_Color>>();
    if (result == null) {
      return null;
    }
    return result._colorFromScheme;
  }

  static Color? onColorOf(BuildContext context) {
    return _toOnColor(context, _adaptiveColorOf(context));
  }

  static Color? secondaryOnColorOf(BuildContext context) {
    return onColorOf(context)?.withAlpha(120);
  }

  static AdaptiveColor? _adaptiveColorOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ColorProvider<_OnColor>>()
        ?.adaptiveColor;
  }

  static Color? _toColor(
    BuildContext context,
    AdaptiveColor? adaptiveColor,
  ) {
    switch (adaptiveColor) {
      case null:
        return null;
      case AdaptiveColor.primary:
        return Theme.of(context).colorScheme.primary;
      case AdaptiveColor.secondary:
        return Theme.of(context).colorScheme.secondary;
      case AdaptiveColor.background:
        return Theme.of(context).colorScheme.background;
      case AdaptiveColor.surface:
        return Theme.of(context).colorScheme.surface;
    }
  }

  static Color? _toOnColor(
    BuildContext context,
    AdaptiveColor? adaptiveColor,
  ) {
    switch (adaptiveColor) {
      case null:
        return null;
      case AdaptiveColor.primary:
        return Theme.of(context).colorScheme.onPrimary;
      case AdaptiveColor.secondary:
        return Theme.of(context).colorScheme.onSecondary;
      case AdaptiveColor.background:
        return Theme.of(context).colorScheme.onBackground;
      case AdaptiveColor.surface:
        return Theme.of(context).colorScheme.onSurface;
    }
  }
}

abstract class _ColorProviderType {}

class _Color implements _ColorProviderType {}

class _OnColor implements _ColorProviderType {}

class _ColorProvider<T extends _ColorProviderType> extends InheritedWidget {
  const _ColorProvider(
    this.adaptiveColor,
    Widget child,
    this._colorFromScheme,
  ) : super(child: child);

  final AdaptiveColor adaptiveColor;

  final Color _colorFromScheme;

  @override
  bool updateShouldNotify(covariant _ColorProvider oldWidget) {
    return oldWidget.adaptiveColor != adaptiveColor ||
        oldWidget._colorFromScheme != _colorFromScheme;
  }
}
