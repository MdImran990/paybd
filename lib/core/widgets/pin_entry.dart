import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import 'pressable_scale.dart';

/// Return an error message to show (and shake), or null on success.
typedef PinSubmit = Future<String?> Function(String pin);

class PinEntry extends StatefulWidget {
  final String title;
  final String subtitle;
  final int length;
  final PinSubmit onCompleted;

  const PinEntry({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onCompleted,
    this.length = 5,
  });

  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _error;
  bool _busy = false;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _tap(String digit) async {
    if (_busy || _pin.length >= widget.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == widget.length) {
      setState(() => _busy = true);
      final err = await widget.onCompleted(_pin);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _pin = '';
        _error = err;
      });
      if (err != null) {
        HapticFeedback.heavyImpact();
        _shake.forward(from: 0);
      }
    }
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(widget.title,
                key: ValueKey(widget.title),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(widget.subtitle,
                key: ValueKey(widget.subtitle),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _shake,
            builder: (_, child) => Transform.translate(
              offset: Offset(
                math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++)
                  AnimatedScale(
                    scale: i < _pin.length ? 1.25 : 1,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length
                            ? AppColors.primary
                            : AppColors.panel,
                        border: Border.all(
                          color: _error != null
                              ? AppColors.error
                              : i < _pin.length
                                  ? AppColors.primary
                                  : AppColors.textMuted.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 22,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AnimatedOpacity(
                    opacity: _error == null ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Text(_error ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),
          ),
          const Spacer(),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final d in row) _Key(label: d, onTap: () => _tap(d)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 68, height: 68),
                _Key(label: '0', onTap: () => _tap('0')),
                _Key(icon: Icons.backspace_outlined, onTap: _back),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  const _Key({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.9,
      child: Material(
        color: AppColors.panel,
        elevation: 1.5,
        shadowColor: const Color(0x33000000),
        surfaceTintColor: Colors.transparent,
        shape: const CircleBorder(),
        child: InkResponse(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 68,
            height: 68,
            child: Center(
              child: label != null
                  ? Text(label!,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600))
                  : Icon(icon, size: 24, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
