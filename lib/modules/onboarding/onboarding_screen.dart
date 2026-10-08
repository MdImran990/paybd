import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
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
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  itemBuilder: (_, i) => _OnboardPage(data: _pages[i]),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _index,
                builder: (_, current, _) => Column(
                  children: [
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
                      label:
                          current == _pages.length - 1 ? 'Get Started' : 'Next',
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final _PageData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.panel,
            boxShadow: [
              BoxShadow(
                color: data.color.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(data.icon, size: 80, color: data.color),
        ),
        const SizedBox(height: 40),
        Tr(
          data.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Tr(
          data.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, height: 1.5),
        ),
      ],
    ),
    );
  }
}
