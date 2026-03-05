// lib/widgets/streak_calendar.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — STREAK CALENDAR WIDGET
//  GitHub-style heatmap showing the last 30 days of focus.
//  Tiles are color-coded by focus intensity (minutes).
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakCalendar extends StatelessWidget {
  /// Map of `dayKey` to `focusMinutes` e.g. {"2026-03-04": 45, ...}
  final Map<String, int> focusData;

  const StreakCalendar({
    super.key,
    required this.focusData,
  });

  Color _tileColor(int minutes) {
    if (minutes == 0)  return const Color(0xFF1A1A2A);
    if (minutes < 15)  return const Color(0xFF2D4A2D);
    if (minutes < 30)  return const Color(0xFF3A6B3A);
    if (minutes < 60)  return const Color(0xFF4CAF50);
    if (minutes < 90)  return const Color(0xFF66D466);
    return const Color(0xFF88F088);
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Generate last 35 days (5 complete weeks)
    final days = List.generate(35, (i) => now.subtract(Duration(days: 34 - i)));

    // Count active days
    final activeDays = days.where((d) {
      final key = _dayKey(d);
      return (focusData[key] ?? 0) > 0;
    }).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF141420),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'FOCUS CALENDAR',
                style: GoogleFonts.spaceMono(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF706A5C),
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                '$activeDays/35 days active',
                style: GoogleFonts.spaceMono(
                  fontSize: 8,
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Day labels
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((label) {
              return Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.spaceMono(
                      fontSize: 7,
                      color: const Color(0xFF706A5C),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),

          // Heatmap grid (5 rows x 7 cols)
          ...List.generate(5, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: List.generate(7, (col) {
                  final idx = row * 7 + col;
                  final day = days[idx];
                  final key = _dayKey(day);
                  final minutes = focusData[key] ?? 0;
                  final isToday = day.day == now.day &&
                      day.month == now.month &&
                      day.year == now.year;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Tooltip(
                          message: '${day.month}/${day.day}: ${minutes}min',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: _tileColor(minutes),
                              border: isToday
                                  ? Border.all(
                                      color: const Color(0xFFF7E7CE)
                                          .withValues(alpha: 0.5),
                                      width: 1,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),

          const SizedBox(height: 6),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less ',
                style: GoogleFonts.spaceMono(
                  fontSize: 7,
                  color: const Color(0xFF706A5C),
                ),
              ),
              ...[ 0, 15, 30, 60, 90 ].map((m) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: _tileColor(m),
                  ),
                );
              }),
              Text(
                ' More',
                style: GoogleFonts.spaceMono(
                  fontSize: 7,
                  color: const Color(0xFF706A5C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
