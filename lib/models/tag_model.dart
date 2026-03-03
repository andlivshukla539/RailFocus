// lib/models/tag_model.dart
// =========================
// Pre-defined session tags for categorization.

import 'package:flutter/material.dart';

class SessionTag {
  final String id;
  final String label;
  final String emoji;
  final Color color;

  const SessionTag({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'emoji': emoji,
    'color': color.toARGB32(),
  };

  factory SessionTag.fromMap(Map<String, dynamic> map) {
    return SessionTag(
      id: map['id'] as String,
      label: map['label'] as String,
      emoji: map['emoji'] as String,
      color: Color(map['color'] as int),
    );
  }

  static const List<SessionTag> allTags = [
    SessionTag(
      id: 'work',
      label: 'Work',
      emoji: '💼',
      color: Color(0xFF5B9BD5),
    ),
    SessionTag(
      id: 'study',
      label: 'Study',
      emoji: '📚',
      color: Color(0xFF9B85D4),
    ),
    SessionTag(
      id: 'reading',
      label: 'Reading',
      emoji: '📖',
      color: Color(0xFF6D8B74),
    ),
    SessionTag(
      id: 'creative',
      label: 'Creative',
      emoji: '🎨',
      color: Color(0xFFE8A87C),
    ),
    SessionTag(
      id: 'exercise',
      label: 'Exercise',
      emoji: '🏋️',
      color: Color(0xFFFF6B35),
    ),
    SessionTag(
      id: 'meditation',
      label: 'Meditation',
      emoji: '🧘',
      color: Color(0xFF00D9FF),
    ),
  ];

  static SessionTag? fromId(String id) {
    try {
      return allTags.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
