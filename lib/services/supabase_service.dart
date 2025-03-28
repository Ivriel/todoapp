import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  // Authentication: Login
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth
        .signInWithPassword(email: email, password: password);
  }

// get current username
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // Authentication: Sign Up
  Future<AuthResponse> signUp(String email, String password) async {
    return await supabase.auth.signUp(email: email, password: password);
  }

  // Logout
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Get Tasks (for logged in user)
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

  // Add Task - Now returns the task ID
  Future<int> addTask(
      String title, String description, DateTime deadline) async {
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
          })
          .select()
          .single();

      return response['id'] as int;
    } catch (e) {
      print('Error adding task: $e');
      throw e;
    }
  }

  // Update Task Status
  Future<void> updateTaskStatus(int taskId, bool isCompleted) async {
    try {
      await supabase
          .from('tasks')
          .update({'is_completed': isCompleted}).eq('id', taskId);
    } catch (e) {
      print('Error updating task status: $e');
      throw e;
    }
  }

  // Update Task
  Future<void> updateTask(int taskId, String title, String description,
      DateTime deadline, bool isCompleted) async {
    try {
      await supabase.from('tasks').update({
        'title': title,
        'description': description,
        'deadline': deadline.toIso8601String(),
        'is_completed': isCompleted,
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
