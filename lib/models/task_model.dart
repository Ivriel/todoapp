// lib/models/task_model.dart
class Task {
  final int id;
  final String userId;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.isCompleted,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      deadline: DateTime.parse(map['deadline']),
      isCompleted: map['is_completed'] ?? false,
    );
  }
}
