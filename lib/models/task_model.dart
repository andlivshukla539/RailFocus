// lib/models/task_model.dart
// ==========================
// Mini to-do items for individual focus sessions.

class SessionTask {
  final String id;
  final String text;
  bool completed;

  SessionTask({required this.id, required this.text, this.completed = false});

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'completed': completed,
  };

  factory SessionTask.fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    return SessionTask(
      id: map['id'] as String,
      text: map['text'] as String,
      completed: map['completed'] as bool? ?? false,
    );
  }

  SessionTask copyWith({bool? completed}) =>
      SessionTask(id: id, text: text, completed: completed ?? this.completed);
}
