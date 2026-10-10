import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/i18n/tr.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/confetti.dart';
import '../../core/widgets/copy_receipt_button.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/receipt_card.dart';
import '../../data/models/transaction.dart';

class ReceiptScreen extends StatelessWidget {
  final Transaction tx;
  const ReceiptScreen({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    // The money has already moved, so going "back" must not repeat the payment.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            const _AnimatedCheck(),
                            const SizedBox(height: 18),
                            FadeSlideIn(
                              index: 3,
                              child: Column(
                                children: [
                                  Tr(tx.type.successTitle,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Tr(formatTaka(tx.amountMinor),
                                      style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.green)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeSlideIn(index: 5, child: ReceiptCard(tx: tx)),
                            const SizedBox(height: 8),
                            FadeSlideIn(
                                index: 6, child: CopyReceiptButton(tx: tx)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      index: 7,
                      child: PrimaryButton(
                        label: 'Done',
                        onPressed: () => context.go('/home'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned.fill(
              child: RepaintBoundary(child: ConfettiBurst()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green circle that pops in, then the check mark draws itself.
class _AnimatedCheck extends StatefulWidget {
  const _AnimatedCheck();

  @override
  State<_AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<_AnimatedCheck> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  static double _seg(double t, double a, double b) {
    final x = (t - a) / (b - a);
    return x < 0 ? 0 : (x > 1 ? 1 : x);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      builder: (_, t, _) {
        final circle = Curves.elasticOut.transform(_seg(t, 0, 0.6));
        final check = Curves.easeOut.transform(_seg(t, 0.4, 0.9));
        return Transform.scale(
          scale: circle,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green,
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CustomPaint(painter: _CheckPainter(check)),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  const _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.27, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.36);
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
