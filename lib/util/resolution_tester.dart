import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResolutionTester extends StatefulWidget {
  const ResolutionTester({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<ResolutionTester> createState() => _ResolutionTesterState();
}

class _ResolutionTesterState extends State<ResolutionTester> {
  late double _maxWidth;
  late double _maxHeight;
  int? _width;
  int? _height;

  @override
  void didChangeDependencies() {
    if (_width == null) {
      final Size size = MediaQuery.of(context).size;
      _maxWidth = size.width;
      _maxHeight = size.height;
      _width ??= _maxWidth.toInt();
      _height ??= _maxHeight.toInt();
    }
    super.didChangeDependencies();
  }

  void _updateWidth(double delta) {
    setState(() {
      _width = (_width! + delta).clamp(0, _maxWidth).toInt();
    });
  }

  void _updateHeight(double delta) {
    setState(() {
      _height = (_height! + delta).clamp(0, _maxHeight).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData query = MediaQuery.of(context);
    return Material(
      color: Colors.grey,
      child: Stack(
        children: [
          Positioned(
            width: _width?.toDouble(),
            height: _height?.toDouble(),
            child: MediaQuery(
              data: query.copyWith(
                size: Size(
                  _width?.toDouble() ?? _maxWidth,
                  _height?.toDouble() ?? _maxHeight,
                ),
              ),
              child: widget.child,
            ),
          ),
          _Controls(
            display: Text(
              'ratio: ${MediaQuery.of(context).devicePixelRatio}\n'
              'logical: $_width x $_height\n'
              'actual: ${_actualPixels(_width!)} x '
              '${_actualPixels(_height!)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
              ),
            ),
            updateWidth: _updateWidth,
            updateHeight: _updateHeight,
          ),
        ],
      ),
    );
  }

  int _actualPixels(num pixels) {
    return (pixels * MediaQuery.of(context).devicePixelRatio).round().toInt();
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    Key? key,
    required this.display,
    required this.updateWidth,
    required this.updateHeight,
  }) : super(key: key);

  final Widget display;
  final void Function(double) updateWidth;
  final void Function(double) updateHeight;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom,
      child: Card(
        child: Row(
          children: [
            const Icon(Icons.drag_handle),
            display,
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_circle_up),
                  onPressed: () => updateHeight(-10),
                ),
                IconButton(
                  icon: Transform.rotate(
                    child: const Icon(Icons.arrow_circle_down),
                    angle: math.pi / 2,
                  ),
                  onPressed: () => updateWidth(-10),
                ),
              ],
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_circle_down),
                  onPressed: () => updateHeight(10),
                ),
                IconButton(
                  icon: Transform.rotate(
                    child: const Icon(Icons.arrow_circle_down),
                    angle: -math.pi / 2,
                  ),
                  onPressed: () => updateWidth(10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
