// lib/screens/onboarding_screen.dart
// ═══════════════════════════════════════════════════════════════
//  THE GRAND STATION — FIRST-TIME ENTRY EXPERIENCE
//
//  Three cinematic steps:
//  1. THE ARRIVAL     — Animated station reveal, steam / bokeh particles
//  2. PASSENGER RECORD — User enters their name (printed on ticket)
//  3. THE GOLDEN TICKET — Shimmering ticket card, slide-to-punch gesture
//
//  Persists: name → SharedPreferences 'passenger_name'
//            done  → SharedPreferences 'onboarding_completed'
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router/app_router.dart' show markOnboardingDone, AppRouter;

// ──────────────────────────────────────────────────────────────
// PALETTE (shared with rest of app)
// ──────────────────────────────────────────────────────────────
class _C {
  static const ink = Color(0xFF07090F);
  static const panel = Color(0xFF131620);
  static const surface = Color(0xFF1A1E2C);
  static const brass = Color(0xFFD4A853);
  static const brassLt = Color(0xFFF0CC7A);
  static const brassDk = Color(0xFF8A6930);
  static const cream = Color(0xFFF5EDDB);
  static const t2 = Color(0xFF9A8E78);
  static const t3 = Color(0xFF564E40);
}

// ──────────────────────────────────────────────────────────────
// SHARED PREFS HELPERS
// ──────────────────────────────────────────────────────────────
class OnboardingPrefs {
  static Future<void> markCompleted(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('passenger_name', name.trim().isEmpty ? 'Traveller' : name.trim());
  }

  static Future<String> getPassengerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('passenger_name') ?? 'Traveller';
  }
}

// ──────────────────────────────────────────────────────────────
// PRE-BAKED STEAM PARTICLE DATA
// ──────────────────────────────────────────────────────────────
class _SteamParticle {
  final double x, speed, size, phase, drift;
  const _SteamParticle(this.x, this.speed, this.size, this.phase, this.drift);
}

final _kSteam = List<_SteamParticle>.unmodifiable(
  List.generate(30, (i) {
    final r = math.Random(i * 17 + 3);
    return _SteamParticle(
      r.nextDouble(),
      0.2 + r.nextDouble() * 0.6,
      12 + r.nextDouble() * 28,
      r.nextDouble() * math.pi * 2,
      (r.nextDouble() - 0.5) * 40,
    );
  }),
);

// ──────────────────────────────────────────────────────────────
// MAIN SCREEN
// ──────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  // ── Stage tracking ─────────────────────────────────────────
  int _stage = 0; // 0=Arrival 1=Passenger Record 2=Golden Ticket

  // ── Animation controllers ──────────────────────────────────
  late final AnimationController _ambientCtrl;   // slow ambient glow
  late final AnimationController _revealCtrl;    // stage-enter reveal
  late final AnimationController _steamCtrl;     // looping steam
  late final AnimationController _ticketCtrl;    // ticket shimmer loop
  late final AnimationController _exitCtrl;      // final fade-to-black

  // ── Name input ─────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  String _name = '';

  // ── Slide-to-punch ─────────────────────────────────────────
  double _sliderProgress = 0.0;   // 0.0 → 1.0
  bool _ticketPunched = false;

  // ── Flags ──────────────────────────────────────────────────
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _steamCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _ticketCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _revealCtrl.dispose();
    _steamCtrl.dispose();
    _ticketCtrl.dispose();
    _exitCtrl.dispose();
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ── Stage transitions ──────────────────────────────────────
  void _advanceStage() {
    if (_stage == 1) {
      // Validate name entry before proceeding
      final trimmed = _nameCtrl.text.trim();
      if (trimmed.isEmpty) {
        HapticFeedback.heavyImpact();
        _nameFocus.requestFocus();
        return;
      }
      setState(() => _name = trimmed.isEmpty ? 'Traveller' : trimmed);
    }
    HapticFeedback.mediumImpact();
    _revealCtrl.forward(from: 0);
    setState(() {
      _stage++;
      if (_stage == 2) {
        _sliderProgress = 0;
        _ticketPunched = false;
      }
    });
  }

  // ── Complete onboarding ────────────────────────────────────
  Future<void> _completeSelf() async {
    if (_isExiting) return;
    _isExiting = true;

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.heavyImpact();

    await OnboardingPrefs.markCompleted(_name);
    markOnboardingDone();

    await _exitCtrl.forward();
    if (mounted) context.go(AppRouter.home);
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (_, child) {
        return Opacity(
          opacity: (1 - _exitCtrl.value).clamp(0.0, 1.0),
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: _C.ink,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Ambient background glow ─────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambientCtrl,
                builder: (_, __) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 1.3,
                      colors: [
                        _C.brass.withValues(alpha: 0.04 + _ambientCtrl.value * 0.05),
                        _C.ink,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Steam particles (always visible) ───────────
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _steamCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _SteamPainter(t: _steamCtrl.value),
                  ),
                ),
              ),
            ),

            // ── Stage content ───────────────────────────────
            AnimatedBuilder(
              animation: _revealCtrl,
              builder: (_, child) => Opacity(
                opacity: Curves.easeOut.transform(_revealCtrl.value.clamp(0.0, 1.0)),
                child: Transform.translate(
                  offset: Offset(0, (1 - Curves.easeOutCubic.transform(_revealCtrl.value.clamp(0.0, 1.0))) * 30),
                  child: child,
                ),
              ),
              child: _buildCurrentStage(),
            ),

            // ── Vignette ────────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.0,
                      colors: [Colors.transparent, _C.ink.withValues(alpha: 0.55)],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStage() {
    switch (_stage) {
      case 0: return _StageArrival(
        ambientCtrl: _ambientCtrl,
        onContinue: _advanceStage,
      );
      case 1: return _StagePassengerRecord(
        nameCtrl: _nameCtrl,
        nameFocus: _nameFocus,
        onContinue: _advanceStage,
      );
      case 2: return _StageGoldenTicket(
        name: _name.isEmpty ? 'Traveller' : _name,
        sliderProgress: _sliderProgress,
        ticketPunched: _ticketPunched,
        ticketCtrl: _ticketCtrl,
        onSlide: (v) {
          setState(() => _sliderProgress = v);
          if (v >= 1.0 && !_ticketPunched) {
            setState(() => _ticketPunched = true);
            _completeSelf();
          }
        },
      );
      default: return const SizedBox.shrink();
    }
  }
}

// ══════════════════════════════════════════════════════════════
// STAGE 1 — THE ARRIVAL
// ══════════════════════════════════════════════════════════════
class _StageArrival extends StatelessWidget {
  final AnimationController ambientCtrl;
  final VoidCallback onContinue;

  const _StageArrival({required this.ambientCtrl, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Station arch icon
          AnimatedBuilder(
            animation: ambientCtrl,
            builder: (_, child) => Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF1F2130), _C.ink],
                ),
                border: Border.all(
                  color: _C.brass.withValues(alpha: 0.25 + ambientCtrl.value * 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.brass.withValues(alpha: (0.1 + ambientCtrl.value * 0.15).clamp(0.0, 1.0)),
                    blurRadius: 50,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: child,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🏛️', style: TextStyle(fontSize: 52)),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Label
          Text(
            'THE GRAND STATION',
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _C.brass,
              letterSpacing: 3.5,
            ),
          ),

          const SizedBox(height: 16),

          // Main headline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Welcome, Traveller.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: _C.cream,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Brass divider
          _BrassDivider(),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Text(
              'The rails await.\nYour focus, your journey.\nStep through the archway.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: _C.t2,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const Spacer(flex: 3),

          // CTA button
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
            child: _GrandButton(
              label: 'ENTER THE STATION',
              icon: Icons.east_rounded,
              onTap: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STAGE 2 — PASSENGER RECORD
// ══════════════════════════════════════════════════════════════
class _StagePassengerRecord extends StatelessWidget {
  final TextEditingController nameCtrl;
  final FocusNode nameFocus;
  final VoidCallback onContinue;

  const _StagePassengerRecord({
    required this.nameCtrl,
    required this.nameFocus,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height
                - MediaQuery.of(context).padding.top
                - MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Conductor illustration
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.panel,
                    border: Border.all(color: _C.brass.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Center(
                    child: Text('🎩', style: TextStyle(fontSize: 48)),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'PASSENGER RECORD',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _C.brass,
                    letterSpacing: 3.5,
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '"What name shall we\nprint on your ticket?"',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: _C.cream,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '— The Conductor',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 13,
                    color: _C.t3,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 40),

                // Name input field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _C.brass.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: _C.brass.withValues(alpha: 0.08),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: nameCtrl,
                      focusNode: nameFocus,
                      autofocus: false,
                      cursorColor: _C.brass,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: _C.cream,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 24,
                      decoration: InputDecoration(
                        hintText: 'Your Name',
                        hintStyle: GoogleFonts.cormorantGaramond(
                          fontSize: 26,
                          fontStyle: FontStyle.italic,
                          color: _C.t3,
                        ),
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                      ),
                      onSubmitted: (_) => onContinue(),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                  child: _GrandButton(
                    label: 'REGISTER PASSENGER',
                    icon: Icons.edit_note_rounded,
                    onTap: onContinue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STAGE 3 — THE GOLDEN TICKET
// ══════════════════════════════════════════════════════════════
class _StageGoldenTicket extends StatelessWidget {
  final String name;
  final double sliderProgress;
  final bool ticketPunched;
  final AnimationController ticketCtrl;
  final ValueChanged<double> onSlide;

  const _StageGoldenTicket({
    required this.name,
    required this.sliderProgress,
    required this.ticketPunched,
    required this.ticketCtrl,
    required this.onSlide,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Header text
          Text(
            'FIRST CLASS',
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _C.brass,
              letterSpacing: 4,
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Your golden ticket\nhas been prepared.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: _C.cream,
                height: 1.15,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 36),

          // Golden Ticket Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedBuilder(
              animation: ticketCtrl,
              builder: (_, __) {
                final shimmer = ticketCtrl.value;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2A2210),
                        const Color(0xFF1A1608),
                        const Color(0xFF2A2210),
                      ],
                    ),
                    border: Border.all(
                      color: _C.brass.withValues(alpha: 0.4 + shimmer * 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.brass.withValues(alpha: (0.08 + shimmer * 0.12).clamp(0.0, 1.0)),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Shimmer overlay
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: CustomPaint(
                            painter: _ShimmerPainter(progress: shimmer),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FIRST CLASS',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 7,
                                        color: _C.brass,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'BOARDING PASS',
                                      style: GoogleFonts.cormorantGaramond(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: _C.brassLt,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [_C.brassLt, _C.brass, _C.brassDk],
                                    ),
                                  ),
                                  child: const Icon(Icons.train_rounded, color: _C.ink, size: 22),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Divider with dots
                            Row(
                              children: List.generate(30, (i) => Expanded(
                                child: Container(
                                  height: 1,
                                  color: i % 2 == 0
                                      ? _C.brass.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                ),
                              )),
                            ),

                            const SizedBox(height: 20),

                            // Passenger name
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PASSENGER',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 7,
                                          color: _C.t2,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        name.toUpperCase(),
                                        style: GoogleFonts.cormorantGaramond(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: _C.cream,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'CLASS',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 7,
                                        color: _C.t2,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'FIRST',
                                      style: GoogleFonts.cormorantGaramond(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: _C.brassLt,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DEPARTS',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 7,
                                          color: _C.t2,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      Text(
                                        'NOW',
                                        style: GoogleFonts.cormorantGaramond(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: _C.cream,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'DESTINATION',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 7,
                                          color: _C.t2,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      Text(
                                        'DEEP FOCUS',
                                        style: GoogleFonts.cormorantGaramond(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: _C.cream,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Barcode strip
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  colors: [
                                    _C.brass.withValues(alpha: 0.6),
                                    _C.brassLt.withValues(alpha: 0.8),
                                    _C.brass.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌',
                                  style: TextStyle(
                                    fontSize: 6,
                                    color: _C.ink.withValues(alpha: 0.4),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Slide to punch instruction
          if (!ticketPunched) ...[
            Text(
              'SLIDE TO PUNCH YOUR TICKET',
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                color: _C.t2,
                letterSpacing: 2.5,
              ),
            ),

            const SizedBox(height: 14),

            // Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _SlideToBoard(
                progress: sliderProgress,
                onChanged: onSlide,
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF1A3A1A),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'TICKET PUNCHED — ALL ABOARD!',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SLIDE-TO-BOARD WIDGET
// ══════════════════════════════════════════════════════════════
class _SlideToBoard extends StatelessWidget {
  final double progress;
  final ValueChanged<double> onChanged;

  const _SlideToBoard({required this.progress, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const trackHeight = 56.0;
    const knobSize = 48.0;

    return LayoutBuilder(builder: (_, constraints) {
      final trackWidth = constraints.maxWidth;
      final maxKnob = trackWidth - knobSize - 8;
      final knobX = progress * maxKnob;
      final filled = progress;

      return Container(
        height: trackHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _C.surface,
          border: Border.all(color: _C.brass.withValues(alpha: 0.25)),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Filled track
            FractionallySizedBox(
              widthFactor: filled.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    colors: [
                      _C.brassDk.withValues(alpha: 0.5),
                      _C.brass.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),

            // Track label
            Center(
              child: Opacity(
                opacity: (1 - filled * 3).clamp(0.0, 1.0),
                child: Text(
                  'SLIDE   →   PUNCH',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _C.t2,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            // Draggable knob
            Positioned(
              left: knobX + 4,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final newX = (knobX + details.delta.dx).clamp(0.0, maxKnob);
                  onChanged(newX / maxKnob);
                  HapticFeedback.selectionClick();
                },
                onHorizontalDragEnd: (_) {
                  if (progress < 0.95) onChanged(0.0);
                },
                child: Container(
                  width: knobSize,
                  height: knobSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_C.brassLt, _C.brass, _C.brassDk],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.brass.withValues(alpha: 0.5),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.train_rounded, color: _C.ink, size: 24),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ══════════════════════════════════════════════════════════════
class _GrandButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GrandButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_C.brassLt, _C.brass, _C.brassDk],
          ),
          boxShadow: [
            BoxShadow(
              color: _C.brass.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _C.ink,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: _C.ink, size: 20),
          ],
        ),
      ),
    );
  }
}

class _BrassDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _C.brass],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _C.brass,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_C.brass, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════
class _SteamPainter extends CustomPainter {
  final double t;
  const _SteamPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;
    for (final p in _kSteam) {
      final progress = (t * p.speed + p.phase / (math.pi * 2)) % 1.0;
      final x = p.x * size.width + math.sin(progress * math.pi * 3) * p.drift;
      final y = size.height - progress * size.height * 1.3;
      final alpha = (math.sin(progress * math.pi).clamp(0.0, 1.0) * 0.07).clamp(0.0, 1.0);
      paint.color = _C.t2.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), p.size * (0.5 + progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_SteamPainter o) => o.t != t;
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  const _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width + progress * size.width * 3;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        _C.brassLt.withValues(alpha: 0.07),
        _C.brassLt.withValues(alpha: 0.14),
        _C.brassLt.withValues(alpha: 0.07),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      transform: GradientRotation(0),
    ).createShader(Rect.fromLTWH(x, 0, size.width, size.height));

    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(_ShimmerPainter o) => o.progress != progress;
}
