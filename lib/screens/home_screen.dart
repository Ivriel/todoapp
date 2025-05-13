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
    if (!mounted) return;
    final data = await supaService.getTasks();
    if (!mounted) return;
    setState(() {
      tasks = data;
    });
  }

  void signOut() async {
    if (!mounted) return;
    await supaService.signOut();
    if (!mounted) return;
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
    // Buat update real time setiap detiknya
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
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AppBar(
            title: const Text(
              'DoManage',
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
                            onPressed: () => Navigator.pop(
                                context, false), // Tutup dialognya
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context,
                                  true); // Tutup dialog terus lanjut logout
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
                      signOut(); // kalau pengguna  Logout, langsung panggil signOut() wir
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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_formatEmail(),
                style: const TextStyle(
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
                const Text(
                  'Datetime',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 25),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM y').format(_currentTime),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('HH:mm:ss').format(_currentTime),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    Row(children: [
                      const Icon(Icons.assignment, color: Colors.yellow),
                      const SizedBox(width: 3),
                      Text("Tasks: ${tasks.length}",
                          style: const TextStyle(
                              color: Colors.yellow, fontSize: 14)),
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 3),
                      Text(
                        'Completed: ${tasks.where((task) => task.isCompleted).length}',
                        style:
                            const TextStyle(color: Colors.green, fontSize: 14),
                      ),
                    ]),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.assignment_late,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Remaining: ${tasks.where((task) => !task.isCompleted).length}',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        )
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const Text(
            'My Tasks',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                fetchTasks();
              },
              child: tasks.isEmpty
                  ? const Center(
                      child: Text('No tasks yet. Tap + to add tasks'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];

                        // pilih warna container
                        final bgColor = task.isCompleted
                            ? Colors.grey.shade300 // lebih gelap saat selesai
                            : Colors.white; // putih saat belum selesai

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await supaService.updateTaskStatus(
                                task.id, !task.isCompleted);
                            fetchTasks();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // --- Top actions (edit/delete) ---
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Edit
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AddTaskScreen(task: task),
                                          ),
                                        ).then((_) => fetchTasks());
                                      },
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            const Color(0xFFF0E6FF),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Color(0xFFA252ED),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Delete
                                    GestureDetector(
                                      onTap: () async {
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Hapus tugas?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Batal'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await supaService.deleteTask(task.id);
                                          fetchTasks();
                                        }
                                      },
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            const Color(0xFFFFECEC),
                                        child: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // --- Title ---
                                Text(
                                  task.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 8),

                                // --- Description ---
                                if (task.description.isEmpty)
                                  // Jika kosong, tampilkan “No description” di tengah
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        'No description',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                else
                                  // Jika ada, tampilkan seperti biasa
                                  Expanded(
                                    child: Text(
                                      task.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                const Spacer(),

                                // --- LABEL DEADLINE ---
                                Text(
                                  'DEADLINE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: task.isCompleted
                                        ? Colors.grey[600]
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // --- Tanggal (pill) ---
                                Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        task.deadline.isBefore(DateTime.now())
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    DateFormat('EEEE, d MMM yyyy')
                                        .format(task.deadline),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          task.deadline.isBefore(DateTime.now())
                                              ? Colors.red
                                              : Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // --- Jam (pill) ---
                                Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    DateFormat('HH:mm').format(task.deadline),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
