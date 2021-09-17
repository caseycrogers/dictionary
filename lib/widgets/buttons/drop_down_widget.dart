import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/widgets/adaptive_material/adaptive_icon_button.dart';
import 'package:rogers_dictionary/widgets/adaptive_material/adaptive_material.dart';

class DropDownWidget extends StatefulWidget {
  const DropDownWidget({
    required this.builder,
    required this.icon,
    this.padding,
    this.selectedColor,
  });

  final Widget Function(BuildContext, VoidCallback) builder;
  final Widget icon;
  final EdgeInsets? padding;
  final Color? selectedColor;

  @override
  _DropDownWidgetState createState() => _DropDownWidgetState();
}

class _DropDownWidgetState extends State<DropDownWidget>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 100),
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isMounted) {
          return true;
        }
        _toggle();
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isMounted
              ? widget.selectedColor ?? Colors.white10
              : Colors.transparent,
        ),
        child: AdaptiveIconButton(
          splashColor: widget.selectedColor,
          highlightColor: widget.selectedColor,
          icon: widget.icon,
          onPressed: () => _toggle(),
        ),
      ),
    );
  }

  OverlayEntry _buildOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final Offset upperLeft = renderBox.localToGlobal(Offset.zero);
    bool onLeft = true;
    final double width = MediaQuery.of(context).size.width;
    if (upperLeft.dx > width / 2) {
      onLeft = false;
    }
    return OverlayEntry(
      builder: (_) => Stack(
        children: [
          FadeTransition(
            opacity: _curve,
            child: Container(
              color: Colors.black38,
              child: GestureDetector(
                onTap: _toggle,
              ),
            ),
          ),
          Positioned(
            top: upperLeft.dy + renderBox.size.height - kPad/2,
            left: onLeft ? upperLeft.dx : null,
            right: onLeft
                ? null
                : width - upperLeft.dx - 2 * renderBox.size.width / 3,
            child: ScaleTransition(
              alignment: Alignment.topRight,
              scale: _curve,
              child: AdaptiveMaterial(
                adaptiveColor: AdaptiveColor.surface,
                child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(2),
                    child: widget.builder(context, _toggle)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle() {
    if (_isMounted) {
      _controller.reverse().then((_) {
        setState(() {
          _overlayEntry?.remove();
          _overlayEntry = null;
        });
      });
      return;
    }
    setState(() {
      _overlayEntry = _buildOverlayEntry();
      Overlay.of(context)!.insert(_overlayEntry!);
      _controller.forward();
    });
  }

  bool get _isMounted => _overlayEntry != null;

  Animation<double> get _curve => CurvedAnimation(
        parent: _controller,
        curve: Curves.fastOutSlowIn,
      );
}
