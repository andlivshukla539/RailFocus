// lib/widgets/shimmer_box.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — SHIMMER LOADING SKELETON
//  A brass-tinted shimmer effect for loading placeholders.
//  Uses a single repaint animation — zero jank.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _ctrl.value * 3, 0),
              end: Alignment(-0.5 + _ctrl.value * 3, 0),
              colors: const [
                Color(0xFF1A1E2C),
                Color(0xFF2A2520),
                Color(0xFF1A1E2C),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A column of shimmer boxes that mimics a loading list
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const ShimmerList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(
          itemCount,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(
              width: double.infinity,
              height: itemHeight,
              borderRadius: 16,
            ),
          ),
        ),
      ),
    );
  }
}
