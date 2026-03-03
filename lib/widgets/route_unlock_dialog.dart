// lib/widgets/route_unlock_dialog.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — ROUTE UNLOCK CELEBRATION
//  Shown when a user's total focus hours cross a route unlock threshold.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/route_model.dart';
import '../services/audio_service.dart';

class RouteUnlockDialog extends StatefulWidget {
  final RouteModel route;
  const RouteUnlockDialog({super.key, required this.route});

  /// Convenience method to show the dialog.
  static Future<void> show(BuildContext context, RouteModel route) {
    HapticFeedback.heavyImpact();
    AudioService().playImportantClick();
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Route Unlock',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 500),
      transitionBuilder: (ctx, a, b, child) {
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(curved),
          child: FadeTransition(opacity: a, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => RouteUnlockDialog(route: route),
    );
  }

  @override
  State<RouteUnlockDialog> createState() => _RouteUnlockDialogState();
}

class _RouteUnlockDialogState extends State<RouteUnlockDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brass = Color(0xFFD4A853);
    const brassLt = Color(0xFFF0CC7A);
    const brassDk = Color(0xFF8A6930);
    const cream = Color(0xFFF5EDDB);
    const ink = Color(0xFF07090F);

    final r = widget.route;

    return Center(
      child: AnimatedBuilder(
        animation: _glow,
        builder:
            (_, child) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF131620),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: brass.withValues(alpha: 0.3 + _glow.value * 0.3),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brass.withValues(alpha: 0.1 + _glow.value * 0.15),
                    blurRadius: 50,
                    spreadRadius: 15,
                  ),
                ],
              ),
              child: child,
            ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Unlock icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [brassLt, brass, brassDk],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brass.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(r.emoji, style: const TextStyle(fontSize: 32)),
                    const Icon(Icons.lock_open_rounded, color: ink, size: 16),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // "NEW ROUTE UNLOCKED"
              Text(
                '🎉 NEW ROUTE UNLOCKED',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: brass,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 14),

              // Route name
              Text(
                r.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: cream,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 8),

              // Route description
              Text(
                r.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: cream.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              // Unlock requirement
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_open_rounded,
                    color: brass.withValues(alpha: 0.6),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Unlocked at ${r.unlockHoursRequired}h focus',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: brass.withValues(alpha: 0.7),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // CTA
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [brassLt, brass, brassDk],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: brass.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    'EXPLORE ROUTE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
