import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../i18n/tr.dart';

/// What the bottom row of the keypad contains.
enum KeypadKind {
  /// [back] [0] [next arrow]
  next,

  /// [.] [0] [back]  (for amounts)
  decimal,

  /// [ ] [0] [back]  (for PINs and codes)
  pin,
}

const _keyLight = Color(0xFFFBE4EE);
const _keyDark = Color(0xFFF5CADC);

/// Pink on-screen number pad. Emits '0'-'9', '.', 'back', 'clear' and 'next'.
class PayKeypad extends StatelessWidget {
  final void Function(String key) onKey;
  final KeypadKind kind;

  /// true = white panel with padding for the bottom of a page; false = just the keys.
  final bool docked;

  const PayKeypad({
    super.key,
    required this.onKey,
    this.kind = KeypadKind.next,
    this.docked = true,
  });

  Widget _row(List<Widget> keys) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: keys[i]),
            ],
          ],
        ),
      );

  Widget _digit(String d) => _PadKey(
        color: _keyLight,
        onTap: () => onKey(d),
        child: Tr(d,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      );

  Widget _back() => _PadKey(
        color: _keyDark,
        onTap: () => onKey('back'),
        onLongPress: () => onKey('clear'),
        child: const Icon(Icons.backspace_outlined,
            size: 22, color: AppColors.primaryDark),
      );

  @override
  Widget build(BuildContext context) {
    final Widget left;
    final Widget right;
    switch (kind) {
      case KeypadKind.next:
        left = _back();
        right = _PadKey(
          color: AppColors.primary,
          onTap: () => onKey('next'),
          child: const Icon(Icons.arrow_forward_rounded,
              size: 24, color: Colors.white),
        );
      case KeypadKind.decimal:
        left = _PadKey(
          color: _keyLight,
          onTap: () => onKey('.'),
          child: const Text('.',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        );
        right = _back();
      case KeypadKind.pin:
        left = const SizedBox(height: 54);
        right = _back();
    }

    final grid = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row([_digit('1'), _digit('2'), _digit('3')]),
        _row([_digit('4'), _digit('5'), _digit('6')]),
        _row([_digit('7'), _digit('8'), _digit('9')]),
        _row([left, _digit('0'), right]),
      ],
    );

    if (!docked) return grid;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        2 + MediaQuery.of(context).padding.bottom,
      ),
      child: grid,
    );
  }
}

class _PadKey extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  const _PadKey({
    required this.color,
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  @override
  State<_PadKey> createState() => _PadKeyState();
}

class _PadKeyState extends State<_PadKey> {
  bool _down = false;

  void _set(bool v) {
    if (mounted && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _down
                ? Color.lerp(widget.color, Colors.black, 0.08)
                : widget.color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
