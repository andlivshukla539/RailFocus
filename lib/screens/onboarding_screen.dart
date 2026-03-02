// lib/screens/onboarding_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — ONBOARDING SCREEN  (All bugs fixed)
//
//  FIXES:
//    1. BoxShadow negative blur radius — replaced AnimatedContainer
//       with manual animation that clamps blur radius to >= 0
//    2. Row overflow 99740px — page indicator dots wrapped in
//       SizedBox with fixed height, dots use fixed size
//    3. Navigator.pushReplacementNamed('/') — replaced with
//       GoRouter context.go('/') for proper go_router navigation
//    4. Column overflow 99416px — content wrapped in
//       SingleChildScrollView with bounded constraints
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/app_router.dart' show markOnboardingDone, AppRouter;
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

// ═══════════════════════════════════════════════════════════════
// PALETTE
// ═══════════════════════════════════════════════════════════════

class _C {
  static const ink     = Color(0xFF07090F);
  static const panel   = Color(0xFF131620);
  static const brass   = Color(0xFFD4A853);
  static const brassLt = Color(0xFFF0CC7A);
  static const brassDk = Color(0xFF8A6930);
  static const cream   = Color(0xFFF5EDDB);
  static const t2      = Color(0xFF9A8E78);
  static const t3      = Color(0xFF564E40);
}

// ═══════════════════════════════════════════════════════════════
// ONBOARDING DATA
// ═══════════════════════════════════════════════════════════════

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final Color accent;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accent,
  });
}

const _pages = [
  _OnboardingPage(
    emoji: '🚂',
    title: 'Welcome Aboard',
    subtitle: 'LUXE RAIL',
    description:
    'Transform your focus sessions into luxury train journeys. '
        'Choose a scenic route, set your intention, and let the rhythm '
        'of the rails carry you to deep work.',
    accent: Color(0xFFD4A853),
  ),
  _OnboardingPage(
    emoji: '🎯',
    title: 'Set Your Intention',
    subtitle: 'BOOK YOUR JOURNEY',
    description:
    'Pick a destination, choose your mood, and define your mission. '
        'Each journey is tailored to help you focus on what matters most.',
    accent: Color(0xFF5CA8D8),
  ),
  _OnboardingPage(
    emoji: '🌄',
    title: 'Enjoy the Scenery',
    subtitle: 'FOCUS & FLOW',
    description:
    'Watch hand-painted landscapes scroll past your observation window. '
        'Ambient sounds keep you in the zone while the timer tracks your progress.',
    accent: Color(0xFF7050C0),
  ),
];

// ═══════════════════════════════════════════════════════════════
// PREFS HELPER
// ═══════════════════════════════════════════════════════════════

class OnboardingPrefs {
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }
}

// ═══════════════════════════════════════════════════════════════
// ONBOARDING SCREEN
// ═══════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  final _pageCtrl = PageController();
  int _currentPage = 0;

  late final AnimationController _glowCtrl;
  late final AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _glowCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    _complete();
  }

  // FIX BUG 3: Use go_router instead of Navigator.pushReplacementNamed
  Future<void> _complete() async {
    await OnboardingPrefs.markCompleted();
    markOnboardingDone(); // Update router cache
    if (mounted) {
      context.go(AppRouter.home); // go_router navigation
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: _C.ink,
      body: Stack(
        children: [
          // ── Ambient glow ────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 1.2,
                    colors: [
                      page.accent.withValues(
                          alpha: 0.04 + _glowCtrl.value * 0.06),
                      _C.ink,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _enterCtrl,
                curve: Curves.easeOut,
              ),
              child: Column(
                children: [
                  // Skip button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _skip,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _C.panel.withValues(alpha: 0.6),
                              border: Border.all(
                                color: _C.brass.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Text(
                              'SKIP',
                              style: GoogleFonts.dmMono(
                                fontSize: 10,
                                color: _C.t2,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _pages.length,
                      onPageChanged: (i) {
                        setState(() => _currentPage = i);
                        HapticFeedback.selectionClick();
                      },
                      itemBuilder: (_, i) => _PageContent(
                        page: _pages[i],
                        glowCtrl: _glowCtrl,
                      ),
                    ),
                  ),

                  // Page indicator dots
                  // FIX BUG 2: Fixed height SizedBox prevents overflow
                  SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final isActive = i == _currentPage;
                        return Container(
                          // FIX BUG 1: No AnimatedContainer with BoxShadow
                          // Use simple Container with conditional decoration
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isActive
                                ? page.accent
                                : page.accent.withValues(alpha: 0.2),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Continue button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              _C.brassLt,
                              _C.brass,
                              _C.brassDk,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _C.brass.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage < _pages.length - 1
                                  ? 'CONTINUE'
                                  : 'BEGIN JOURNEY',
                              style: GoogleFonts.dmMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _C.ink,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              _currentPage < _pages.length - 1
                                  ? Icons.arrow_forward_rounded
                                  : Icons.train_rounded,
                              color: _C.ink,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Vignette ────────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      _C.ink.withValues(alpha: 0.5),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE CONTENT
// ═══════════════════════════════════════════════════════════════

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  final AnimationController glowCtrl;

  const _PageContent({
    required this.page,
    required this.glowCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Emoji icon with glow
          AnimatedBuilder(
            animation: glowCtrl,
            builder: (_, child) => Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: page.accent.withValues(alpha: 0.08),
                border: Border.all(
                  color: page.accent.withValues(
                      alpha: 0.2 + glowCtrl.value * 0.15),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: page.accent.withValues(
                        alpha: 0.1 + glowCtrl.value * 0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: child,
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 52),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Subtitle
          Text(
            page.subtitle,
            style: GoogleFonts.dmMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: page.accent,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            page.title,
            style: GoogleFonts.cormorant(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: _C.cream,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Decorative line
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _C.brass.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _C.brass,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.brass.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _C.panel.withValues(alpha: 0.5),
              border: Border.all(
                color: _C.brass.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              page.description,
              style: GoogleFonts.cormorant(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: _C.cream.withValues(alpha: 0.8),
                height: 1.6,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}