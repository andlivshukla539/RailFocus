// lib/models/focus_project.dart
// ═══════════════════════════════════════════════════════════════
//  FOCUS PROJECT — tags a session to a meaningful project
//  Stored in its own Hive box 'projects' as JSON maps.
// ═══════════════════════════════════════════════════════════════

class FocusProject {
  final String id;
  final String name;
  final String emoji;
  final String colorHex; // e.g. '#D4A853'

  const FocusProject({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorHex,
  });

  // ── Serialization ──────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'colorHex': colorHex,
  };

  factory FocusProject.fromMap(Map<dynamic, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);
    return FocusProject(
      id: m['id'] as String,
      name: m['name'] as String,
      emoji: m['emoji'] as String,
      colorHex: m['colorHex'] as String,
    );
  }

  // Convenience: parse the hex string to a Flutter Color int
  int get colorValue {
    final hex = colorHex.replaceAll('#', '');
    return int.parse('FF$hex', radix: 16);
  }

  // ── Preset palettes ───────────────────────────────────────
  static const presets = [
    FocusProject(id: '', name: '', emoji: '💼', colorHex: '#D4A853'),
    FocusProject(id: '', name: '', emoji: '📚', colorHex: '#7E9CC9'),
    FocusProject(id: '', name: '', emoji: '🎨', colorHex: '#C97E9C'),
    FocusProject(id: '', name: '', emoji: '💡', colorHex: '#9CC97E'),
    FocusProject(id: '', name: '', emoji: '🚀', colorHex: '#9E7EC9'),
    FocusProject(id: '', name: '', emoji: '🏋️', colorHex: '#C99E7E'),
  ];
}
