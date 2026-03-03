// lib/widgets/animated_counter.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — ANIMATED COUNTER
//  Numbers that count up from 0 when they appear on screen.
//  Supports int and double display with optional suffix.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class AnimatedCounter extends StatefulWidget {
  final double value;
  final int decimals;
  final TextStyle? style;
  final String suffix;
  final Duration duration;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.decimals = 0,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1200),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _prevValue = old.value;
      _anim = Tween<double>(
        begin: _prevValue,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final val = _anim.value;
        final text =
            widget.decimals > 0
                ? val.toStringAsFixed(widget.decimals)
                : val.round().toString();
        return Text('$text${widget.suffix}', style: widget.style);
      },
    );
  }
}
