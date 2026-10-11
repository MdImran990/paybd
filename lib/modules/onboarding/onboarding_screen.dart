import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/i18n/tr.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/primary_button.dart';

class _PageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _PageData(this.icon, this.title, this.subtitle, this.color);
}

const _pages = <_PageData>[
  _PageData(
    Icons.send_rounded,
    'Send money easily',
    'Send and receive money with just a phone number.',
    AppColors.primary,
  ),
  _PageData(
    Icons.receipt_long_rounded,
    'Pay bills & recharge',
    'Mobile recharge, electricity, WiFi and more in one place.',
    AppColors.green,
  ),
  _PageData(
    Icons.qr_code_scanner_rounded,
    'Pay with QR',
    'Scan a QR code and pay at your favourite stores.',
    AppColors.blue,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final _index = ValueNotifier<int>(0);

  @override
  void dispose() {
    _controller.dispose();
    _index.dispose();
    super.dispose();
  }

  void _next() {
    if (_index.value == _pages.length - 1) {
      context.go('/login');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Current (fractional) page, safe to call before the first layout.
  double _pageOf(int fallback) {
    try {
      if (_controller.hasClients) {
        return _controller.page ?? fallback.toDouble();
      }
    } catch (_) {}
    return fallback.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _index,
      builder: (_, current, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        // The background slowly takes the colour of the current page.
        color: Color.lerp(AppColors.bg, _pages[current].color, 0.07),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Tr('Skip',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) => _index.value = i,
                      itemBuilder: (_, i) => AnimatedBuilder(
                        animation: _controller,
                        builder: (_, _) => _OnboardPage(
                          data: _pages[i],
                          delta: _pageOf(current) - i,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: i == current ? 26 : 8,
                          decoration: BoxDecoration(
                            color: i == current
                                ? AppColors.primary
                                : AppColors.panel,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: current == _pages.length - 1 ? 'Get Started' : 'Next',
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One page. [delta] is how far it is from the centre (-1 .. 1), which drives the parallax.
class _OnboardPage extends StatelessWidget {
  final _PageData data;
  final double delta;
  const _OnboardPage({required this.data, required this.delta});

  @override
  Widget build(BuildContext context) {
    final d = delta.clamp(-1.0, 1.0).toDouble();
    final away = d.abs();
    return FadeSlideIn(
      child: Opacity(
        opacity: 1 - away * 0.7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The icon moves faster than the text, and shrinks as it leaves.
            Transform.translate(
              offset: Offset(-d * 120, 0),
              child: Transform.scale(
                scale: 1 - away * 0.25,
                child: _FloatingIcon(data: data),
              ),
            ),
            const SizedBox(height: 40),
            Transform.translate(
              offset: Offset(-d * 50, 0),
              child: Tr(
                data.title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            Transform.translate(
              offset: Offset(-d * 30, 0),
              child: Tr(
                data.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon in a glowing circle that gently floats up and down.
class _FloatingIcon extends StatefulWidget {
  final _PageData data;
  const _FloatingIcon({required this.data});

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, math.sin(_c.value * math.pi) * -10),
        child: child,
      ),
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.panel,
          boxShadow: [
            BoxShadow(
              color: widget.data.color.withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(widget.data.icon, size: 80, color: widget.data.color),
      ),
    );
  }
}
