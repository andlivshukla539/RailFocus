// lib/screens/app_blocker_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — APP BLOCKER SETTINGS
//  Manage which apps to block during focus sessions.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/app_blocker_service.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

class _P {
  static const ink = Color(0xFF07090F);
  static const panel = Color(0xFF131620);
  static const surface = Color(0xFF1A1E2C);
  static const brass = Color(0xFFD4A853);
  static const cream = Color(0xFFF5EDDB);
  static const muted = Color(0xFF706A5C);
  static const red = Color(0xFFEF5350);
}

class AppBlockerScreen extends StatefulWidget {
  const AppBlockerScreen({super.key});

  @override
  State<AppBlockerScreen> createState() => _AppBlockerScreenState();
}

class _AppBlockerScreenState extends State<AppBlockerScreen> {
  final _blocker = AppBlockerService.instance;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _blocker.load();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _P.cream),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'APP BLOCKER',
          style: GoogleFonts.cinzel(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _P.brass,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      body: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: _P.brass),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1218), Color(0xFF131620)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _P.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🚫', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BLOCK DISTRACTIONS',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _P.red,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Selected apps will be blocked during your focus sessions. Stay on the rails! 🚂',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 13,
                                  color: _P.cream.withValues(alpha: 0.7),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 24),

                  // Section title
                  _sectionTitle('POPULAR APPS'),
                  const SizedBox(height: 12),

                  // App list
                  ...AppBlockerService.commonApps
                      .asMap()
                      .entries
                      .map((entry) {
                    final i = entry.key;
                    final app = entry.value;
                    final packageName = app['package']!;
                    final isBlocked =
                        _blocker.blockedApps.contains(packageName);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await _blocker.toggleApp(packageName);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _P.panel,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isBlocked
                                  ? _P.red.withValues(alpha: 0.3)
                                  : _P.surface.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                app['emoji']!,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  app['name']!,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _P.cream,
                                  ),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 26,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  color: isBlocked
                                      ? _P.red.withValues(alpha: 0.8)
                                      : _P.surface,
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  alignment: isBlocked
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isBlocked
                                          ? Colors.white
                                          : _P.muted,
                                    ),
                                    child: isBlocked
                                        ? const Icon(
                                            Icons.block_rounded,
                                            size: 12,
                                            color: _P.red,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: 50 * i))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.05, end: 0);
                  }),

                  const SizedBox(height: 24),

                  // Stats
                  Center(
                    child: Text(
                      '${_blocker.blockedApps.length} apps will be blocked during focus',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: _P.muted,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _P.red,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _P.muted,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
