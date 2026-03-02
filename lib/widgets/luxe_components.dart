// lib/widgets/luxe_components.dart
// ================================
// Reusable premium UI components for Luxe Rail.

import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/luxe_theme.dart';

// ══════════════════════════════════════════════════════════════
// LUXE DIVIDER
// ══════════════════════════════════════════════════════════════

class LuxeDivider extends StatelessWidget {
  final String? label;
  final IconData? icon;

  const LuxeDivider({super.key, this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    LuxeColors.gold.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          if (label != null || icon != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: LuxeColors.gold.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: LuxeColors.gold, size: 14),
                    if (label != null) const SizedBox(width: 8),
                  ],
                  if (label != null)
                    Text(
                      label!,
                      style: GoogleFonts.cinzel(
                        color: LuxeColors.gold,
                        fontSize: 11,
                        letterSpacing: 2.0,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LuxeColors.gold.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// GLASS CARD
// ══════════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool selected;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.borderColor,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = selected
        ? LuxeColors.gold
        : (borderColor ?? Colors.white.withValues(alpha: 0.1));

    return GestureDetector(
      onTap: onTap != null
          ? () {
        HapticFeedback.lightImpact();
        onTap!();
      }
          : null,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: selected ? 0.12 : 0.08),
              Colors.white.withValues(alpha: selected ? 0.06 : 0.02),
            ],
          ),
          border: Border.all(
            color: effectiveBorderColor,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: LuxeColors.gold.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LUXE BUTTON
// ══════════════════════════════════════════════════════════════

class LuxeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;
  final bool loading;

  const LuxeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.enabled = true,
    this.loading = false,
  });

  @override
  State<LuxeButton> createState() => _LuxeButtonState();
}

class _LuxeButtonState extends State<LuxeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !widget.loading;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GestureDetector(
          onTap: enabled
              ? () {
            HapticFeedback.mediumImpact();
            widget.onPressed?.call();
          }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: enabled
                    ? LuxeColors.sunriseGold
                    : [LuxeColors.slate, LuxeColors.charcoal],
              ),
              boxShadow: enabled
                  ? [
                BoxShadow(
                  color: LuxeColors.gold.withValues(
                    alpha: 0.3 + _pulseController.value * 0.2,
                  ),
                  blurRadius: 20 + _pulseController.value * 10,
                  spreadRadius: _pulseController.value * 5,
                ),
              ]
                  : null,
            ),
            child: Center(
              child: widget.loading
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    LuxeColors.obsidian,
                  ),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: enabled
                          ? LuxeColors.obsidian
                          : LuxeColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    widget.label,
                    style: GoogleFonts.cinzel(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: enabled
                          ? LuxeColors.obsidian
                          : LuxeColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LUXE TEXT FIELD
// ══════════════════════════════════════════════════════════════

class LuxeTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;

  const LuxeTextField({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.maxLines = 3,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LuxeDecorations.glassCard(borderRadius: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            maxLength: maxLength,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              color: LuxeColors.champagne,
            ),
            cursorColor: LuxeColors.gold,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                color: LuxeColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
              contentPadding: const EdgeInsets.all(20),
              border: InputBorder.none,
              counterStyle: GoogleFonts.inter(
                fontSize: 11,
                color: LuxeColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION HEADER
// ══════════════════════════════════════════════════════════════

class LuxeSectionHeader extends StatelessWidget {
  final int stepNumber;
  final int totalSteps;
  final String title;
  final String? subtitle;

  const LuxeSectionHeader({
    super.key,
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        Row(
          children: [
            ...List.generate(totalSteps, (i) {
              final isActive = i < stepNumber;
              final isCurrent = i == stepNumber - 1;
              return Container(
                width: isCurrent ? 24 : 8,
                height: 4,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isActive
                      ? LuxeColors.gold
                      : LuxeColors.gold.withValues(alpha: 0.2),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text(
              'STEP $stepNumber OF $totalSteps',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: LuxeColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Title
        Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: LuxeColors.champagne,
            letterSpacing: 1.0,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 14,
              color: LuxeColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ANIMATED PARTICLES (for backgrounds)
// ══════════════════════════════════════════════════════════════

class LuxeParticles extends StatefulWidget {
  final Color color;
  final int count;

  const LuxeParticles({
    super.key,
    this.color = LuxeColors.gold,
    this.count = 30,
  });

  @override
  State<LuxeParticles> createState() => _LuxeParticlesState();
}

class _LuxeParticlesState extends State<LuxeParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(
            progress: _controller.value,
            color: widget.color,
            count: widget.count,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int count;

  _ParticlePainter({
    required this.progress,
    required this.color,
    required this.count,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    for (int i = 0; i < count; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      final floatOffset = math.sin(progress * math.pi * 2 + i * 0.7) * 30;
      final driftX = math.cos(progress * math.pi * 2 * 0.4 + i * 1.1) * 20;

      final x = baseX + driftX;
      final y = baseY + floatOffset;

      final phase = random.nextDouble() * math.pi * 2;
      final opacity = (math.sin(progress * math.pi * 2 + phase) + 1) / 2 * 0.15;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(x, y), 3 + random.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}