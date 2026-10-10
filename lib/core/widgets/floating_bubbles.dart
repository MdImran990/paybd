import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Soft translucent circles that drift slowly behind a header, so the pink areas feel alive.
/// Put it in a Positioned.fill inside a Stack.
class FloatingBubbles extends StatefulWidget {
  const FloatingBubbles({super.key});

  @override
  State<FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<FloatingBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _bubble({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value * 2 * math.pi;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _bubble(
                right: -50 + 16 * math.sin(t),
                top: -60 + 12 * math.cos(t),
                size: 200,
                opacity: 0.09,
              ),
              _bubble(
                left: -40 + 14 * math.cos(t + 1),
                bottom: -30 + 12 * math.sin(t + 2),
                size: 140,
                opacity: 0.07,
              ),
              _bubble(
                right: 70 + 10 * math.sin(t + 3),
                top: 60 + 8 * math.cos(t + 4),
                size: 54,
                opacity: 0.08,
              ),
            ],
          );
        },
      ),
    );
  }
}
