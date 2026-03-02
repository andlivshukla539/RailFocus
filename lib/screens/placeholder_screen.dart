// lib/screens/placeholder_screen.dart
// ====================================
// Temporary placeholder for unimplemented screens.
//
// Fixes applied:
//   ✓ RenderFlex overflow 78px — two root causes:
//       a) SafeArea Column now wrapped in SingleChildScrollView +
//          ConstrainedBox(minHeight) so content scrolls when the
//          keyboard appears and Spacers still work when it's hidden
//       b) Footer padding: all(32) → fromLTRB(32,8,32,28); the
//          original 64px top+bottom padding alone ate most of the
//          overflow budget on compact devices
//   ✓ Background bare Container (unsized inside Stack) → Positioned.fill
//     + DecoratedBox so it actually fills the Stack correctly
//   ✓ Vignette Container → DecoratedBox (already Positioned.fill,
//     Container was wasteful with no child/size)
//   ✓ GoogleFonts.cormorantGaramond → GoogleFonts.cormorant
//   ✓ GoogleFonts.inter → GoogleFonts.dmMono (app-consistent)
//   ✓ Icon() → const Icon() where possible

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/luxe_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String emoji;
  final String hint;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.emoji,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final mq              = MediaQuery.of(context);
    final availableHeight = mq.size.height
        - mq.padding.top
        - mq.padding.bottom;

    return Scaffold(
      backgroundColor: LuxeColors.obsidian,
      body: Stack(
        children: [
          // ── Background gradient ─────────────────────────────────────
          // FIX: was a bare Container with only `decoration:` and no
          // width/height — unsized children in a Stack default to 0×0.
          // Positioned.fill gives it the constraints it needs.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    LuxeColors.obsidian,
                    LuxeColors.velvet,
                    LuxeColors.obsidian,
                  ],
                ),
              ),
            ),
          ),

          // ── Decorative grid ─────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPatternPainter()),
          ),

          // ── Main content ────────────────────────────────────────────
          // FIX: SingleChildScrollView + ConstrainedBox(minHeight):
          //   • When keyboard is hidden: minHeight == available viewport
          //     so Expanded/Spacer children still push things apart.
          //   • When keyboard is shown: scroll view absorbs the push
          //     instead of the Column overflowing.
          // IntrinsicHeight lets the inner Column use Expanded correctly
          // inside a scroll view.
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ── Header ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _BackButton(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.pop();
                              },
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: LuxeColors.gold
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'COMING SOON',
                                // FIX: GoogleFonts.inter → dmMono
                                style: GoogleFonts.dmMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: LuxeColors.gold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.3, end: 0),

                      // ── Centre content ───────────────────────────
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),

                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    LuxeColors.gold.withValues(alpha: 0.15),
                                    LuxeColors.gold.withValues(alpha: 0.05),
                                    Colors.transparent,
                                  ],
                                ),
                                border: Border.all(
                                  color: LuxeColors.gold
                                      .withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 64),
                                ),
                              ),
                            )
                                .animate(delay: 200.ms)
                                .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1, 1),
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            )
                                .fadeIn(),

                            const SizedBox(height: 40),

                            Text(
                              title.toUpperCase(),
                              style: GoogleFonts.cinzel(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: LuxeColors.champagne,
                                letterSpacing: 4,
                              ),
                              textAlign: TextAlign.center,
                            )
                                .animate(delay: 400.ms)
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: 0.2, end: 0),

                            const SizedBox(height: 20),

                            // FIX: GoogleFonts.cormorantGaramond → cormorant
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40),
                              child: Text(
                                hint,
                                style: GoogleFonts.cormorant(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: LuxeColors.champagne
                                      .withValues(alpha: 0.6),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                                .animate(delay: 500.ms)
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: 0.2, end: 0),

                            const SizedBox(height: 48),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildDot(0),
                                const SizedBox(width: 8),
                                _buildDot(1),
                                const SizedBox(width: 8),
                                _buildDot(2),
                              ],
                            ).animate(delay: 700.ms).fadeIn(duration: 500.ms),

                            const Spacer(),
                          ],
                        ),
                      ),

                      // ── Footer ───────────────────────────────────
                      // FIX: padding all(32) → fromLTRB(32, 8, 32, 28)
                      // The original 32px top + 32px bottom = 64px of
                      // vertical padding was the direct overflow culprit.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 8, 32, 28),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.go('/');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: LuxeColors.gold
                                    .withValues(alpha: 0.4),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.white.withValues(alpha: 0.03),
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_back_rounded,
                                  color: LuxeColors.gold,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'BACK TO STATION',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: LuxeColors.champagne,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate(delay: 800.ms)
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.3, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Vignette ────────────────────────────────────────────────
          // FIX: Container → DecoratedBox (no child/size needed here)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
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

  Widget _buildDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LuxeColors.gold.withValues(alpha: 0.5),
      ),
    )
        .animate(
      onPlay: (controller) => controller.repeat(reverse: true),
      delay: Duration(milliseconds: index * 200),
    )
        .scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.2, 1.2),
      duration: 600.ms,
    )
        .then()
        .scale(
      begin: const Offset(1.2, 1.2),
      end: const Offset(0.8, 0.8),
      duration: 600.ms,
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: LuxeColors.champagne,
          size: 18,
        ),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LuxeColors.gold.withValues(alpha: 0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPatternPainter _) => false;
}