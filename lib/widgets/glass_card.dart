// lib/widgets/glass_card.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — GLASSMORPHISM CARD
//  Frosted glass container with blur backdrop + luminous border.
//  Uses ClipRRect + BackdropFilter for real GPU-accelerated blur.
// ═══════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color tint;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.blur = 12,
    this.tint = const Color(0x14F5EDDB),
    this.borderColor = const Color(0x22D4A853),
    this.borderWidth = 1,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: tint,
              border: Border.all(color: borderColor, width: borderWidth),
              // Subtle inner glow via gradient overlay
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.01),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
