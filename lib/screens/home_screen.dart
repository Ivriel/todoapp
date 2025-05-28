import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'add_task_screen.dart';
import '../models/task_model.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService supaService = SupabaseService();
  List<Task> tasks = []; // buat nimpan semua tugas dari supabase

  Timer? _timer; // update waktu real time (buat jam:menit:detik)
  DateTime _currentTime = DateTime.now();

  // Pagination variables
  int _currentPage = 0;
  final int _itemsPerPage = 4;
  int get _totalPages => (tasks.length / _itemsPerPage).ceil();

  List<Task> get _currentPageTasks {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage) > tasks.length 
        ? tasks.length 
        : startIndex + _itemsPerPage;
    return tasks.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void fetchTasks() async { // fetch semua data tugas dari supabase
    if (!mounted) return;
    final data = await supaService.getTasks(); // ambil semua data tugas
    if (!mounted) return;
    setState(() { // update ui kalau udah masuk tugasnya
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
    _timer?.cancel(); 
    super.dispose();
  }

  String _formatEmail() {
    final email = supaService.getCurrentUser()?.email ?? ''; // ambil email dari user terkini.kalau ga ada kasih string kosong
    return 'Welcome Back, ${email.split('@')[0]}'; // ambil email yang sebelum simbol @ aja wes
  }

  String _formatDateTime(DateTime dateTime) {
    final date = DateFormat('dd/MM/yyyy').format(dateTime);
    final hour = dateTime.hour.toString().padLeft(2, '0'); // tambah padding ke jam cek terus dua digit
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  @override
  void initState() {
    super.initState();
    fetchTasks(); // fetch tugas kalau widget udah di load
    // Buat update real time setiap detiknya (live change)
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
            backgroundColor: Colors.transparent,
            elevation: 0,
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
            padding: const EdgeInsets.symmetric(horizontal: 13,vertical: 13),
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
              child: Column(
                children: [
                  Expanded(
                    child: tasks.isEmpty
                        ? const Center(
                            child: Text('No tasks yet. Tap + to add tasks'),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 300,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.52,
                            ),
                            itemCount: _currentPageTasks.length,
                            itemBuilder: (context, index) {
                              final task = _currentPageTasks[index];
                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  if (!task.isCompleted) {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Mark as Complete',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        content: Text(
                                          'Are you sure you want to mark "${task.title}" as complete?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text(
                                              'Complete',
                                              style: TextStyle(
                                                color: Color(0xFFA252ED),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      await supaService.updateTaskStatus(
                                          task.id, !task.isCompleted);
                                      fetchTasks();
                                    }
                                  } else {
                                    await supaService.updateTaskStatus(
                                        task.id, !task.isCompleted);
                                    fetchTasks();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: task.isCompleted
                                        ? Colors.grey.shade300
                                        : Colors.white,
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
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
                                            child: const CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Color(0xFFF0E6FF),
                                              child: Icon(
                                                Icons.edit,
                                                size: 18,
                                                color: Color(0xFFA252ED),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              final confirmed =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('Delete task?'),
                                                  content: const Text(
                                                      'Are you sure to delete task?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(
                                                          context, false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(
                                                          context, true),
                                                      child: const Text(
                                                        'Delete.',
                                                        style: TextStyle(
                                                          color: Colors.red
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                await supaService.deleteTask(task.id);
                                                fetchTasks();
                                              }
                                            },
                                            child: const CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Color(0xFFFFECEC),
                                              child: Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
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
                                      if (task.description.isEmpty)
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
                                        Expanded(
                                          child: Text(
                                            task.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                              height: 1.4,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 5,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      const Spacer(),
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
                                      Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: task.deadline.isBefore(DateTime.now())
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          DateFormat('EEEE, d MMM yyyy')
                                              .format(task.deadline),
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: task.deadline.isBefore(DateTime.now())
                                                ? Colors.red
                                                : Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
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
                  if (tasks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 0
                                ? () => _goToPage(_currentPage - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            color: _currentPage > 0 ? Colors.black : Colors.grey,
                          ),
                          ...List.generate(
                            _totalPages,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () => _goToPage(index),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _currentPage == index
                                        ? const Color(0xFFA252ED)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _currentPage == index
                                          ? const Color(0xFFA252ED)
                                          : Colors.grey,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: _currentPage == index
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _currentPage < _totalPages - 1
                                ? () => _goToPage(_currentPage + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            color: _currentPage < _totalPages - 1
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                ],
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
