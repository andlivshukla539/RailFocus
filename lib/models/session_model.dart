// lib/models/session_model.dart
// =============================
// Data model for a single focus session ("train journey").
//
// LIFECYCLE:
//   1. Created when the user confirms booking
//   2. Updated when the timer ends (completed = true) or
//      the user hits emergency stop (completed = false)
//   3. Stored permanently in Hive for history & stats
//
// STORAGE:
//   Serialized to/from a Map<String, dynamic> so Hive can
//   store it without needing a custom TypeAdapter.

class JourneySession {
  /// Unique identifier — milliseconds since epoch as a string
  final String id;

  /// Display name of the route (e.g., "Tokyo to Kyoto")
  final String routeName;

  /// Planned focus duration in minutes (e.g., 25, 45, 90)
  final int durationMinutes;

  /// When the user started the focus session
  final DateTime startTime;

  /// True if the timer ran to completion without emergency stop
  final bool completed;

  /// How the user was feeling before starting (optional)
  final String? mood;

  /// What the user wanted to accomplish (optional)
  final String? goal;

  /// Post-session reflection note (optional)
  final String? note;

  /// Category tags for this session (e.g., ['work', 'study'])
  final List<String>? tags;

  /// Mini task list for this session
  final List<Map<String, dynamic>>? tasks;

  /// Session category (e.g., 'work', 'study')
  final String? category;

  /// Constructor — all data provided at creation time
  JourneySession({
    required this.id,
    required this.routeName,
    required this.durationMinutes,
    required this.startTime,
    required this.completed,
    this.mood,
    this.goal,
    this.note,
    this.tags,
    this.tasks,
    this.category,
  });

  // ── Computed Properties ──────────────────────────────────

  /// Human-readable duration string.
  ///   15  → "15m"
  ///   60  → "1h"
  ///   90  → "1h 30m"
  String get formattedDuration {
    if (durationMinutes < 60) return '${durationMinutes}m';

    final int hours = durationMinutes ~/ 60; // integer division
    final int mins = durationMinutes % 60; // remainder

    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  // ── Serialization ────────────────────────────────────────

  /// Converts this session into a Map that Hive can store.
  /// DateTime is stored as milliseconds-since-epoch (an int)
  /// because Hive handles ints natively.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeName': routeName,
      'durationMinutes': durationMinutes,
      'startTime': startTime.millisecondsSinceEpoch,
      'completed': completed,
      'mood': mood,
      'goal': goal,
      'note': note,
      'tags': tags,
      'tasks': tasks,
      'category': category,
    };
  }

  /// Creates a JourneySession from a Map retrieved from Hive.
  /// The [Map.from] call ensures we have a proper Dart Map
  /// (Hive sometimes returns a special internal map type).
  factory JourneySession.fromMap(Map<dynamic, dynamic> raw) {
    // Cast to <String, dynamic> for safe key access
    final map = Map<String, dynamic>.from(raw);

    return JourneySession(
      id: map['id'] as String,
      routeName: map['routeName'] as String,
      durationMinutes: map['durationMinutes'] as int,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      completed: map['completed'] as bool,
      mood: map['mood'] as String?,
      goal: map['goal'] as String?,
      note: map['note'] as String?,
      tags: (map['tags'] as List?)?.cast<String>(),
      tasks:
          (map['tasks'] as List?)
              ?.map((t) => Map<String, dynamic>.from(t as Map))
              .toList(),
      category: map['category'] as String?,
    );
  }
}
