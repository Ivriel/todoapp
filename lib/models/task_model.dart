
class Task { // bikin schema kolom kolom di table task dari supabase 
  final int id;
  final String userId;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;
  final int notificationMinutes;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.isCompleted,
    this.notificationMinutes = 15
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      deadline: DateTime.parse(map['deadline']),
      isCompleted: map['is_completed'] ?? false, // buat defaultnya disetting ke salah
      notificationMinutes: map['notification_minutes'] ?? 15 // buat defaultnya disetting ke 15
    );
  }
}
