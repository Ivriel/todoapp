import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart'; // library supaya gampang memformat tanggalnya

class AddTaskScreen extends StatefulWidget {
  final Task? task; // inisialisasi detect. file ini buat edit atau bikin
  const AddTaskScreen({Key? key, this.task}) : super(key: key); // menentukan file ini buat edit apa create

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _notificationTimeController = TextEditingController(text: '15'); // Default value buat inputnya 15 menit 
  final _titleController = TextEditingController(); // buat ngambil nilai dari input
  final _descriptionController = TextEditingController();
  final _supaService = SupabaseService(); // intinya ngambil logika logika yang udah dibuat 
  DateTime _selectedDate = DateTime.now(); // simpan waktu yang di select dari widget
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() { // buat dipanggil waktu widget dimuat
    super.initState();
    if (widget.task != null) { // kalau task nya tidak null , berarti dia edit. jadi pre-load isi form dari data yang akan diedit
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.deadline;
      _selectedTime = TimeOfDay.fromDateTime(widget.task!.deadline);
      _notificationTimeController.text = widget.task!.notificationMinutes.toString(); 
    }
  }

  @override
  void dispose() { // buat hapus memori pas widget ga dipakai supaya ga terjadi memory leak
    _titleController.dispose();
    _descriptionController.dispose();
    _notificationTimeController.dispose(); 
    super.dispose();
  }

  Future<void> _selectDate() async { // buat munculin date picker buat user milih waktu nanti di widget
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) { // update state kalau waktu dipilih
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveTask() async {
    // Validasi judul biar gabisa dikirim kalau kosong
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Please enter a title',
            style: TextStyle(color: Colors.white),
          )));
      return;
    }

    // Validasi waktu notif ben ga ngawur ngisine
    int minutesBefore;
    try {
      minutesBefore = int.parse(_notificationTimeController.text); // tangkap input pengguna (berapa menit sebelum deadline)
      if (minutesBefore <= 0 || minutesBefore > 1440) {
        // 1440 setara dengan 24 jam. 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Please enter a notification time between 1 and 1440 minutes',
            style: TextStyle(color: Colors.white),
          ),
        ));
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'Please enter a valid number for notification time',
          style: TextStyle(color: Colors.white),
        ),
      ));
      return;
    }

    final deadline = DateTime( // format tanggal + jam
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (deadline.isBefore(DateTime.now())) { // validasi jaga-jaga kalau user input deadline di masa lalu atau di waktu user membuat tugas (jam nya). jadi harus di masa depan
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Deadline must be in the future',
              style: TextStyle(color: Colors.white),
            )),
      );
      return;
    }

    try {
      if (widget.task == null) { // kalau null berarti tambah tugas lalu simpen tugas baru sekalian notifikasinya
        // Bikin task include id nya sekalian
        final taskId = await _supaService.addTask(_titleController.text,
            _descriptionController.text, deadline, minutesBefore);

        // Jadwalkan notifikasi ambil dari input yang dimasukkan pengguna
        await NotificationService().scheduleNotification(
          taskId,
          _titleController.text,
          deadline,
          minutesBefore: minutesBefore, 
        );
      } else { // kalauga null berarti lagi edit tugas
        // Batalin notif lama waktu sebelum tugas diedit
        await NotificationService().cancelNotification(widget.task!.id);

        // Update tugas
        await _supaService.updateTask(
            widget.task!.id,
            _titleController.text,
            _descriptionController.text,
            deadline,
            widget.task!.isCompleted,
            minutesBefore);

        // Jadwalin ulang notifikasi baru pakai waktu dari inputan user
        await NotificationService().scheduleNotification(
          widget.task!.id,
          _titleController.text,
          deadline,
          minutesBefore: minutesBefore, 
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task saved successfully',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                          'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectDate,
                    ),
                    const Divider(),
                    ListTile(
                      title: Text('Time: ${_selectedTime.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: _selectTime,
                    ),
                    // Buat milih waktu deadline karep
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      child: TextField(
                        controller: _notificationTimeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              'Notification time (minutes before deadline)',
                          labelStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.black)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16)
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFA252ED),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(
                  widget.task == null ? 'Add Task' : 'Update Task',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
