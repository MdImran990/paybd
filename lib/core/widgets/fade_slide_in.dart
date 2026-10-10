import 'package:flutter/material.dart';

/// Fades and slides its child up when it first appears.
/// Give neighbouring items increasing [index] values for a staggered entrance.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;

  /// Where the child starts (fraction of its own size). Default: a little below.
  final Offset offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 0.12),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final i = widget.index < 0 ? 0 : (widget.index > 12 ? 12 : widget.index);
    final delay = i * 45;
    const base = 420;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: base + delay),
    );
    _anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay / (base + delay), 1.0, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: widget.offset, end: Offset.zero)
            .animate(_anim),
        child: widget.child,
      ),
    );
  }
}
