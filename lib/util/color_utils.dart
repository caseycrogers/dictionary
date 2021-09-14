import 'dart:ui';

extension ColorUtils on Color {
  Color bake(Color backgroundColor) {
    return Color.lerp(backgroundColor, this, opacity)!;
  }
}
