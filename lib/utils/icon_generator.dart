// ═══════════════════════════════════════════════════════════════
//  TEMPORARY UTILITY — Generates the app icon as a PNG.
//  Run once, screenshot/save the result, then delete this file.
//
//  To use:
//    1. Temporarily change your home route to IconGeneratorScreen
//    2. Run the app
//    3. Take a screenshot (1024x1024 recommended)
//    4. Save as assets/icon/icon.png
//    5. Delete this file and restore your route
//
//  OR: Just use the design spec below to create it in Figma/Canva.
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class IconGeneratorScreen extends StatelessWidget {
  const IconGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: 512,
          height: 512,
          decoration: const BoxDecoration(
            color: Color(0xFF07090F),
          ),
          child: CustomPaint(
            size: const Size(512, 512),
            painter: _IconPainter(),
          ),
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Background ─────────────────────────────────────────
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF07090F),
    );

    // ── Outer brass ring ───────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..shader = ui.Gradient.sweep(
          Offset(cx, cy),
          [
            const Color(0xFF8A6930),
            const Color(0xFFD4A853),
            const Color(0xFFF0CC7A),
            const Color(0xFFD4A853),
            const Color(0xFF8A6930),
            const Color(0xFFD4A853),
            const Color(0xFFF0CC7A),
            const Color(0xFFD4A853),
            const Color(0xFF8A6930),
          ],
        ),
    );

    // ── Inner glow ring ────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.38,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFD4A853).withValues(alpha: 0.3),
    );

    // ── Radial gold glow behind icon ───────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.22,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          size.width * 0.22,
          [
            const Color(0xFFD4A853).withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
    );

    // ── Train icon (simplified locomotive silhouette) ──────
    _drawTrain(canvas, cx, cy, size.width * 0.16);

    // ── Corner diamonds ────────────���───────────────────────
    final diamondP = Paint()..color = const Color(0xFFD4A853);
    for (final angle in [0.0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
      final dx = cx + math.cos(angle) * size.width * 0.42;
      final dy = cy + math.sin(angle) * size.width * 0.42;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(
        const Rect.fromLTWH(-5, -5, 10, 10),
        diamondP,
      );
      canvas.restore();
    }

    // ── "LR" monogram ──────────────────────────────────────
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'LR',
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: size.width * 0.065,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD4A853).withValues(alpha: 0.6),
          letterSpacing: 6,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy + size.width * 0.27),
    );
  }

  void _drawTrain(Canvas canvas, double cx, double cy, double scale) {
    final p = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx - scale, cy - scale),
        Offset(cx + scale, cy + scale),
        [
          const Color(0xFFF0CC7A),
          const Color(0xFFD4A853),
          const Color(0xFF8A6930),
        ],
      );

    // Locomotive body (simplified front view)
    final bodyW = scale * 1.4;
    final bodyH = scale * 1.6;

    // Main body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + scale * 0.1),
          width: bodyW,
          height: bodyH,
        ),
        Radius.circular(scale * 0.2),
      ),
      p,
    );

    // Chimney
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - bodyH * 0.42),
          width: scale * 0.35,
          height: scale * 0.5,
        ),
        Radius.circular(scale * 0.08),
      ),
      p,
    );

    // Chimney top flare
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - bodyH * 0.6),
          width: scale * 0.55,
          height: scale * 0.15,
        ),
        Radius.circular(scale * 0.05),
      ),
      p,
    );

    // Headlight
    canvas.drawCircle(
      Offset(cx, cy - scale * 0.15),
      scale * 0.18,
      Paint()..color = const Color(0xFF07090F),
    );
    canvas.drawCircle(
      Offset(cx, cy - scale * 0.15),
      scale * 0.12,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - scale * 0.03, cy - scale * 0.18),
          scale * 0.1,
          [Colors.white, const Color(0xFFFFDD80)],
        ),
    );

    // Cowcatcher base
    final cowPath = Path()
      ..moveTo(cx - bodyW * 0.35, cy + bodyH * 0.5)
      ..lineTo(cx - bodyW * 0.55, cy + bodyH * 0.65)
      ..lineTo(cx + bodyW * 0.55, cy + bodyH * 0.65)
      ..lineTo(cx + bodyW * 0.35, cy + bodyH * 0.5)
      ..close();
    canvas.drawPath(cowPath, p);

    // Wheels (2)
    final wheelP = Paint()..color = const Color(0xFF07090F);
    final rimP = Paint()
      ..color = const Color(0xFFD4A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final wx in [-0.35, 0.35]) {
      final wheelX = cx + bodyW * wx;
      final wheelY = cy + bodyH * 0.55;
      canvas.drawCircle(Offset(wheelX, wheelY), scale * 0.2, wheelP);
      canvas.drawCircle(Offset(wheelX, wheelY), scale * 0.2, rimP);
      canvas.drawCircle(
        Offset(wheelX, wheelY),
        scale * 0.06,
        Paint()..color = const Color(0xFFD4A853),
      );
    }
  }

  @override
  bool shouldRepaint(_IconPainter _) => false;
}