import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'add_task_screen.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService supaService = SupabaseService();
  List<Task> tasks = [];

  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  void fetchTasks() async {
    if (!mounted) return; // Add this check
    final data = await supaService.getTasks();
    if (!mounted) return; // Add this check
    setState(() {
      tasks = data;
    });
  }

  void signOut() async {
    if (!mounted) return; // Add this check
    await supaService.signOut();
    if (!mounted) return; // Add this check
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer when widget is disposed
    // Clean up any subscriptions or listeners here if needed
    super.dispose();
  }

String _formatEmail() {
  final email = supaService.getCurrentUser()?.email ?? '';
  return 'Welcome Back, ${email.split('@')[0]}';
}

  String _formatDateTime(DateTime dateTime) {
    final date = DateFormat('dd/MM/yyyy').format(dateTime);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  @override
  void initState() {
    super.initState();
    fetchTasks();
    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AppBar(
            title: const Text(
              'To-Do List',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: Image.asset(
              'assets/logohome.png',
            ),
            actions: [
              IconButton(
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Text('Are you sure to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false), // Tutup dialog
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context,
                                  true); // Tutup dialog dan lanjut logout
                            },
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      signOut(); // Jika pengguna menekan Logout, panggil signOut()
                    }
                  },
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ))
            ],
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20),
           Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              _formatEmail(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                )),
          ),
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF3A135E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datetime',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 25),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM y').format(_currentTime),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  DateFormat('HH:mm:ss').format(_currentTime),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.assignment, color: Colors.yellow),
                      const SizedBox(width: 3),
                      Text("Tasks: ${tasks.length}",
                          style: TextStyle(color: Colors.yellow, fontSize: 14)),
                    ]),
                    Row(children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 3),
                      Text(
                        'Completed: ${tasks.where((task) => task.isCompleted).length}',
                        style: TextStyle(color: Colors.green, fontSize: 14),
                      ),
                    ]),
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_late,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Remaining: ${tasks.where((task) => !task.isCompleted).length}',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        )
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          Text(
            'My Tasks',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            ),
          SizedBox(height:16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                fetchTasks();
              },
              child: tasks.isEmpty
                  ? const Center(
                      child: Text('No tasks yet. Tap + to add one!'),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  task.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Deadline: ${_formatDateTime(task.deadline)}',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit Button
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color(0xFFA252ED)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddTaskScreen(task: task),
                                      ),
                                    ).then((_) => fetchTasks());
                                  },
                                ),
                                // Delete Button
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Delete Task',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        content: const Text(
                                            'Are you sure you want to delete this task?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Delete',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        // First cancel all notifications for this task
                                        await NotificationService()
                                            .cancelTaskNotifications(task.id);
                                        // Then delete the task
                                        await supaService.deleteTask(task.id);
                                        fetchTasks();
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error deleting task: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () async {
                              await supaService.updateTaskStatus(
                                  task.id, !task.isCompleted);
                              fetchTasks();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFA252ED),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddTaskScreen()),
        ).then((_) => fetchTasks()),
      ),
    );
  }
}
