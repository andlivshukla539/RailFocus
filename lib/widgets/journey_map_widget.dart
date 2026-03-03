// lib/widgets/journey_map_widget.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — JOURNEY MAP WIDGET
//  A visual route map with waypoint stations and animated train.
//  Shows departure → waypoints → arrival with progress indication.
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// ROUTE WAYPOINT
// ═══════════════════════════════════════════════════════════════

class RouteWaypoint {
  final String name;
  final double position; // 0.0 → 1.0 along the route

  const RouteWaypoint(this.name, this.position);
}

// ═══════════════════════════════════════════════════════════════
// PREDEFINED WAYPOINTS PER ROUTE
// ═══════════════════════════════════════════════════════════════

const Map<String, List<RouteWaypoint>> _routeWaypoints = {
  'tokyo_kyoto': [
    RouteWaypoint('TOKYO', 0.0),
    RouteWaypoint('SHIN-YOKOHAMA', 0.18),
    RouteWaypoint('NAGOYA', 0.52),
    RouteWaypoint('KYOTO', 1.0),
  ],
  'swiss_alps': [
    RouteWaypoint('ZÜRICH', 0.0),
    RouteWaypoint('BERN', 0.30),
    RouteWaypoint('VISP', 0.65),
    RouteWaypoint('ZERMATT', 1.0),
  ],
  'scottish_highlands': [
    RouteWaypoint('EDINBURGH', 0.0),
    RouteWaypoint('PERTH', 0.28),
    RouteWaypoint('INVERNESS', 0.62),
    RouteWaypoint('THURSO', 1.0),
  ],
  'darjeeling': [
    RouteWaypoint('NEW JALPAIGURI', 0.0),
    RouteWaypoint('KURSEONG', 0.40),
    RouteWaypoint('GHUM', 0.72),
    RouteWaypoint('DARJEELING', 1.0),
  ],
  'norwegian_fjords': [
    RouteWaypoint('OSLO', 0.0),
    RouteWaypoint('FINSE', 0.35),
    RouteWaypoint('MYRDAL', 0.60),
    RouteWaypoint('BERGEN', 1.0),
  ],
  'trans_siberian': [
    RouteWaypoint('MOSCOW', 0.0),
    RouteWaypoint('YEKATERINBURG', 0.20),
    RouteWaypoint('NOVOSIBIRSK', 0.37),
    RouteWaypoint('IRKUTSK', 0.58),
    RouteWaypoint('KHABAROVSK', 0.82),
    RouteWaypoint('VLADIVOSTOK', 1.0),
  ],
  'orient_express': [
    RouteWaypoint('PARIS', 0.0),
    RouteWaypoint('STRASBOURG', 0.18),
    RouteWaypoint('VIENNA', 0.48),
    RouteWaypoint('BUDAPEST', 0.65),
    RouteWaypoint('ISTANBUL', 1.0),
  ],
  'indian_pacific': [
    RouteWaypoint('SYDNEY', 0.0),
    RouteWaypoint('BROKEN HILL', 0.25),
    RouteWaypoint('ADELAIDE', 0.42),
    RouteWaypoint('COOK', 0.65),
    RouteWaypoint('PERTH', 1.0),
  ],
};

List<RouteWaypoint> waypointsFor(String routeId) =>
    _routeWaypoints[routeId] ??
    const [RouteWaypoint('ORIGIN', 0.0), RouteWaypoint('DESTINATION', 1.0)];

// ═══════════════════════════════════════════════════════════════
// JOURNEY MAP WIDGET
// ═══════════════════════════════════════════════════════════════

class JourneyMapWidget extends StatelessWidget {
  final String routeId;
  final String routeEmoji;
  final int distanceKm;
  final ValueNotifier<double> progress; // 0.0 → 1.0
  final Color accentColor;

  const JourneyMapWidget({
    super.key,
    required this.routeId,
    required this.routeEmoji,
    required this.distanceKm,
    required this.progress,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final waypoints = waypointsFor(routeId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ── Map visualization ──────────────────────────────
          SizedBox(
            height: 80,
            child: ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (_, p, __) => CustomPaint(
                size: const Size(double.infinity, 80),
                painter: _JourneyMapPainter(
                  waypoints: waypoints,
                  progress: p,
                  accent: accentColor,
                  emoji: routeEmoji,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Distance indicator ─────────────────────────────
          ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, p, __) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(p * distanceKm).round()} km',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${(p * 100).round()}% journey',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    color: const Color(0xFF706A5C),
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$distanceKm km total',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    color: const Color(0xFF3E3A32),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// JOURNEY MAP PAINTER
// ═══════════════════════════════════════════════════════════════

class _JourneyMapPainter extends CustomPainter {
  final List<RouteWaypoint> waypoints;
  final double progress;
  final Color accent;
  final String emoji;

  _JourneyMapPainter({
    required this.waypoints,
    required this.progress,
    required this.accent,
    required this.emoji,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height * 0.55;
    final trackLeft = 10.0;
    final trackRight = size.width - 10.0;
    final trackWidth = trackRight - trackLeft;

    // ── Background track (dashed) ───────────────────────────
    final bgPaint = Paint()
      ..color = const Color(0xFF1C1F2E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(trackLeft, trackY),
      Offset(trackRight, trackY),
      bgPaint,
      dashWidth: 6,
      gapWidth: 4,
    );

    // ── Completed track (solid, glowing) ────────────────────
    final progressX = trackLeft + trackWidth * progress.clamp(0.0, 1.0);

    // Glow
    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(
      Offset(trackLeft, trackY),
      Offset(progressX, trackY),
      glowPaint,
    );

    // Solid track
    final trackPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(trackLeft, trackY),
        Offset(progressX, trackY),
        [const Color(0xFFB8824A), accent],
      )
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(trackLeft, trackY),
      Offset(progressX, trackY),
      trackPaint,
    );

    // ── Waypoint stations ───────────────────────────────────
    for (final wp in waypoints) {
      final x = trackLeft + trackWidth * wp.position;
      final isPassed = progress >= wp.position;
      final isCurrent = (progress - wp.position).abs() < 0.05 ||
          (wp == waypoints.last && progress >= 0.95);

      // Station dot
      final dotRadius = isCurrent ? 6.0 : (isPassed ? 5.0 : 4.0);
      final dotPaint = Paint()
        ..color = isPassed ? accent : const Color(0xFF2A2A3A);

      // Outer ring for current station
      if (isCurrent || isPassed) {
        final ringPaint = Paint()
          ..color = accent.withValues(alpha: isPassed ? 0.3 : 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(x, trackY), dotRadius + 3, ringPaint);
      }

      canvas.drawCircle(Offset(x, trackY), dotRadius, dotPaint);

      // Inner bright dot
      if (isPassed) {
        canvas.drawCircle(
          Offset(x, trackY),
          2,
          Paint()..color = const Color(0xFFEDE6D8),
        );
      }

      // Station name label
      final labelStyle = TextStyle(
        fontFamily: 'monospace',
        fontSize: 7,
        fontWeight: isPassed ? FontWeight.w700 : FontWeight.w400,
        color: isPassed
            ? const Color(0xFFEDE6D8).withValues(alpha: 0.9)
            : const Color(0xFF706A5C).withValues(alpha: 0.6),
        letterSpacing: 0.8,
      );

      final tp = TextPainter(
        text: TextSpan(text: wp.name, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // Alternate labels above/below track
      final isAbove = waypoints.indexOf(wp) % 2 == 0;
      final labelY = isAbove ? trackY - 22 : trackY + 14;
      final labelX = (x - tp.width / 2).clamp(0.0, size.width - tp.width);

      tp.paint(canvas, Offset(labelX, labelY));
    }

    // ── Train icon ──────────────────────────────────────────
    final trainX = progressX;
    final trainY = trackY - 16;

    // Train glow
    canvas.drawCircle(
      Offset(trainX, trainY),
      10,
      Paint()
        ..color = accent.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Train emoji background
    canvas.drawCircle(
      Offset(trainX, trainY),
      9,
      Paint()..color = const Color(0xFF141420),
    );
    canvas.drawCircle(
      Offset(trainX, trainY),
      9,
      Paint()
        ..color = accent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Train emoji text
    final emojiPainter = TextPainter(
      text: TextSpan(
        text: '🚂',
        style: const TextStyle(fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    emojiPainter.paint(
      canvas,
      Offset(trainX - emojiPainter.width / 2, trainY - emojiPainter.height / 2),
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 5,
    double gapWidth = 3,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalLength = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / totalLength;
    final unitDy = dy / totalLength;

    double drawn = 0;
    bool drawing = true;
    while (drawn < totalLength) {
      final segLen = drawing ? dashWidth : gapWidth;
      final nextDrawn = (drawn + segLen).clamp(0.0, totalLength);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitDx * drawn, start.dy + unitDy * drawn),
          Offset(start.dx + unitDx * nextDrawn, start.dy + unitDy * nextDrawn),
          paint,
        );
      }
      drawn = nextDrawn;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyMapPainter old) =>
      old.progress != progress;
}
