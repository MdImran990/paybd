import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// One-time confetti burst (about 2.6 seconds). Put it in a Positioned.fill on top of a page.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Particle {
  final double vx;
  final double vy;
  final double spin;
  final double size;
  final Color color;
  final bool circle;
  const _Particle(this.vx, this.vy, this.spin, this.size, this.color, this.circle);
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    AppColors.primary,
    Color(0xFFFFC83D),
    AppColors.green,
    AppColors.blue,
    Color(0xFFFF8AB8),
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  late final List<_Particle> _particles = () {
    final r = math.Random();
    return List.generate(48, (_) {
      return _Particle(
        (r.nextDouble() - 0.5) * 1.3, // sideways speed
        -0.25 - r.nextDouble() * 0.85, // upward speed
        (r.nextDouble() - 0.5) * 2,
        5 + r.nextDouble() * 6,
        _colors[r.nextInt(_colors.length)],
        r.nextBool(),
      );
    });
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _c.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  const _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.2);
    final w = size.width;
    final fade = t < 0.7 ? 1.0 : 1.0 - (t - 0.7) / 0.3;
    final paint = Paint();
    for (final p in particles) {
      final x = origin.dx + p.vx * t * w;
      final y = origin.dy + (p.vy * t + 1.7 * t * t) * w;
      paint.color = p.color.withValues(alpha: fade < 0 ? 0 : fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t * 8);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
