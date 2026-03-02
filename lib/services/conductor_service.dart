// lib/services/conductor_service.dart
// ═══════════════════════════════════════════════════════════════
//  LUXE RAIL — THE CONDUCTOR SERVICE
//
//  Generates elegant, personalized departure announcements
//  based on passenger context: streak, mood, goal, time, history.
//
//  STYLE:
//  • 1-3 cinematic sentences
//  • Under 70 words
//  • No emojis, no exclamation marks
//  • Refined, restrained, emotionally intelligent
//  • Vintage European railway elegance
// ═══════════════════════════════════════════════════════════════

import 'dart:math';

/// Context data for generating personalized announcements
class SessionContext {
  final String? userName;
  final String? goal;
  final String? mood;
  final int durationMinutes;
  final int totalSessions;
  final int currentStreak;
  final bool lastSessionCompleted;
  final String routeName;

  const SessionContext({
    this.userName,
    this.goal,
    this.mood,
    required this.durationMinutes,
    required this.totalSessions,
    required this.currentStreak,
    required this.lastSessionCompleted,
    required this.routeName,
  });

  /// Determines time of day category
  String get timeOfDay {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'lateNight';
  }

  /// Calculates performance trend based on streak
  String get performanceTrend {
    if (currentStreak >= 3) return 'improving';
    if (currentStreak == 0 && !lastSessionCompleted) return 'declining';
    return 'stable';
  }
}

/// The Conductor — generates elegant departure announcements
class ConductorService {
  final _random = Random();

  /// Generates a personalized departure announcement
  String generateAnnouncement(SessionContext context) {
    // Build the announcement based on context
    final parts = <String>[];

    // Opening line (time-aware)
    parts.add(_getOpeningLine(context));

    // Middle content (goal/destination aware)
    parts.add(_getDestinationLine(context));

    // Closing line (context-adaptive)
    parts.add(_getClosingLine(context));

    return parts.where((s) => s.isNotEmpty).join(' ');
  }

  /// Time-of-day aware opening lines
  String _getOpeningLine(SessionContext context) {
    final time = _formatDepartureTime();
    final duration = _formatDuration(context.durationMinutes);

    // Check for milestones first
    if (context.totalSessions >= 100) {
      return _pick([
        'The $time service stands ready once more.',
        'Platform lights dim for a familiar departure.',
        'The $time express awaits its distinguished passenger.',
      ]);
    }

    if (context.currentStreak >= 7) {
      return _pick([
        'The $time service to ${context.routeName} is now boarding.',
        'Your reserved $duration carriage awaits on Platform 1.',
        'The $time departure is prepared, as expected.',
      ]);
    }

    // Time-based openings
    switch (context.timeOfDay) {
      case 'morning':
        return _pick([
          'The $time morning express is ready for departure.',
          'First light finds the $time service prepared.',
          'The morning train to ${context.routeName} now boards.',
        ]);

      case 'afternoon':
        return _pick([
          'The $time afternoon limited awaits.',
          'Your $duration passage is confirmed for the $time departure.',
          'The afternoon service to ${context.routeName} is boarding.',
        ]);

      case 'evening':
        return _pick([
          'The $time evening service is now ready.',
          'Golden hour finds your carriage prepared.',
          'The evening express to ${context.routeName} stands waiting.',
        ]);

      case 'lateNight':
        return _pick([
          'The $time night train prepares for quiet departure.',
          'The late service runs for those who seek stillness.',
          'Your midnight carriage has been made ready.',
        ]);

      default:
        return 'The $time service to ${context.routeName} now boards.';
    }
  }

  /// Goal/destination aware middle lines
  String _getDestinationLine(SessionContext context) {
    final goal = context.goal;
    final duration = _formatDuration(context.durationMinutes);

    // If goal exists, weave it in
    if (goal != null && goal.trim().isNotEmpty) {
      final shortGoal = _truncateGoal(goal);

      return _pick([
        'Your journey toward $shortGoal begins shortly.',
        'The route ahead leads through $shortGoal.',
        '$duration of uninterrupted passage toward $shortGoal.',
        'This train makes no stops until $shortGoal.',
      ]);
    }

    // No specific goal
    return _pick([
      'The scenic route through ${context.routeName} awaits.',
      '$duration of quiet country lies ahead.',
      'The track ahead promises undisturbed passage.',
      '',  // Sometimes no middle line is more elegant
    ]);
  }

  /// Context-adaptive closing lines
  String _getClosingLine(SessionContext context) {
    // Streak recognition (7+ days)
    if (context.currentStreak >= 7) {
      return _pick([
        'The railway notes your consistency.',
        'Seven days the train has found you ready.',
        'Discipline needs no announcement.',
        'We depart on schedule, as always.',
      ]);
    }

    // Returning after missed session
    if (context.currentStreak == 0 && !context.lastSessionCompleted) {
      return _pick([
        'The train departs regardless. Your seat remains.',
        'We resume the journey.',
        'The schedule continues.',
        'All passengers return eventually.',
      ]);
    }

    // High session count (50+)
    if (context.totalSessions >= 50) {
      return _pick([
        'A familiar route for a seasoned traveler.',
        'The conductor remembers.',
        'Another chapter in a longer journey.',
        '',
      ]);
    }

    // Improving trend
    if (context.performanceTrend == 'improving') {
      return _pick([
        'The momentum of the rails carries forward.',
        'Each departure builds upon the last.',
        'We depart shortly.',
        '',
      ]);
    }

    // Default closings
    return _pick([
      'We depart shortly.',
      'Please take your seat.',
      'The platform lights are dimming.',
      'Final boarding.',
      'The whistle sounds in moments.',
      '',
    ]);
  }

  /// Formats current time as departure time (e.g., "7:45")
  String _formatDepartureTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = (now.minute ~/ 5) * 5; // Round to nearest 5
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Formats duration elegantly
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes-minute';
    } else if (minutes == 60) {
      return 'one-hour';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours-hour';
      }
      return '$hours hour $mins minute';
    }
  }

  /// Truncates goal to a destination-like phrase
  String _truncateGoal(String goal) {
    // Clean up the goal
    var clean = goal.trim();

    // If it's short enough, use as-is
    if (clean.length <= 30) {
      return clean.toLowerCase();
    }

    // Truncate to first phrase or meaningful segment
    final firstPhrase = clean.split(RegExp(r'[,.\-—]')).first.trim();
    if (firstPhrase.length <= 35) {
      return firstPhrase.toLowerCase();
    }

    // Take first few words
    final words = clean.split(' ');
    if (words.length <= 4) {
      return clean.toLowerCase();
    }

    return words.take(4).join(' ').toLowerCase();
  }

  /// Picks a random item from a list
  String _pick(List<String> options) {
    final nonEmpty = options.where((s) => s.isNotEmpty).toList();
    if (nonEmpty.isEmpty) return '';
    return nonEmpty[_random.nextInt(nonEmpty.length)];

  }
}