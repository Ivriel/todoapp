import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import 'notification_service.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  // Buat autentikasi user berdasarkan email sama pw
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth
        .signInWithPassword(email: email, password: password);
  }

// nama user saat ini berdasarkan email
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // gawe sign up
  Future<AuthResponse> signUp(String email, String password) async {
    return await supabase.auth.signUp(email: email, password: password);
  }

  // fungsi buat log out 
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Buat tampilkan list tugas buat user yang baru login 
  Future<List<Task>> getTasks() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('deadline', ascending: true);

      final data = response as List;
      return data.map((e) => Task.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  // Bikin tugas sekalikan bikin id tugasnya
  Future<int> addTask(
      String title, String description, DateTime deadline, int notificationMinutes) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('tasks')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'deadline': deadline.toIso8601String(),
            'is_completed': false,
            'notification_minutes': notificationMinutes, 
          })
          .select()
          .single();

      return response['id'] as int;
    } catch (e) {
      print('Error adding task: $e');
      throw e;
    }
  }

  // Update status tugas udah selesai apa belum
Future<void> updateTaskStatus(int taskId, bool isCompleted) async {
  try {
    // Ambil tugas terkini sebelum diupdate
    final response = await supabase
        .from('tasks')
        .select()
        .eq('id', taskId)
        .single();
    
    final task = Task.fromMap(response);

    // Update status tugas
    await supabase
        .from('tasks')
        .update({'is_completed': isCompleted})
        .eq('id', taskId);

    print('Task ${task.title} (ID: $taskId) status updated to: ${isCompleted ? 'completed' : 'incomplete'}');

    // Handle notifikasi
    if (isCompleted) {
      
      print('Cancelling notifications for completed task');
      await NotificationService().cancelTaskNotifications(taskId);
    } else {
      
      if (task.deadline.isAfter(DateTime.now())) {
        print('Rescheduling notifications for uncompleted task');
        
        await NotificationService().scheduleNotification(
          taskId,
          task.title,
          task.deadline,
        );
      } else {
        print('Task deadline has passed, not scheduling notifications');
      }
    }
  } catch (e) {
    print('Error in updateTaskStatus: $e');
    throw e;
  }
}

  // Update Task
  Future<void> updateTask(int taskId, String title, String description,
      DateTime deadline, bool isCompleted,int notificationMinutes) async {
    try {
      await supabase.from('tasks').update({
        'title': title,
        'description': description,
        'deadline': deadline.toIso8601String(),
        'is_completed': isCompleted,
        'notification_minutes':notificationMinutes
      }).eq('id', taskId);
    } catch (e) {
      print('Error updating task: $e');
      throw e;
    }
  }

  // Delete Task
  Future<void> deleteTask(int taskId) async {
    try {
      await supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      print('Error deleting task: $e');
      throw e;
    }
  }
}