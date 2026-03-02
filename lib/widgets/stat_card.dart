// lib/widgets/stat_card.dart
// ===========================
// A reusable card widget that displays a single stat.
// Used on the Home Screen to show streak and total hours.
// By making it a separate widget, both stats share identical
// layout code — changing the card style updates both at once.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class StatCard extends StatelessWidget {
  // The small uppercase label above the number e.g. "CURRENT STREAK"
  final String label;

  // The large number or value displayed e.g. "7" or "12.5"
  final String value;

  // The unit shown after the value e.g. "days" or "hrs"
  final String unit;

  // An emoji or icon character shown on the card e.g. "🔥"
  final String emoji;

  // Optional: tint the card border with a specific color
  // Defaults to the standard amber glow
  final Color? accentColor;

  // Optional animation delay — lets cards stagger their entrance
  // Pass Duration(milliseconds: 200) for the second card, etc.
  final Duration animationDelay;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.emoji,
    this.accentColor,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve the accent color — use provided color or default amber
    final color = accentColor ?? AppColors.amber;

    return Container(
      // Internal padding — breathing room for the content
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        // Card background
        color: AppColors.card,

        // Rounded corners
        borderRadius: BorderRadius.circular(16),

        // Border with a subtle amber tint
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),

        // A very subtle glow behind the card using a box shadow
        // This gives it the "lit from within" premium feel
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        // Align content to the left edge of the card
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Top Row: emoji + label ────────────────────────────
          Row(
            children: [
              // The emoji icon
              Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),

              // Uppercase label text
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Value Row: number + unit ───────────────────────────
          Row(
            // Align the value and unit to the baseline
            // so they line up correctly despite different font sizes
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [

              // The large primary number
              Text(
                value,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.0,    // Tight line height for the big number
                ),
              ),

              const SizedBox(width: 6),

              // The unit label next to the number
              Text(
                unit,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    )
    // Animate the card entrance using flutter_animate.
    // .animate() creates an animation controller automatically.
    // .fadeIn() + .slideY() chain to create a fade-up entrance.
        .animate(delay: animationDelay)
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(
      begin: 0.15,   // Start 15% below final position
      end: 0,        // End at final position
      duration: 600.ms,
      curve: Curves.easeOutCubic,
    );
  }
}