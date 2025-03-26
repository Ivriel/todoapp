import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart'; // Add this import
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  const AddTaskScreen({Key? key, this.task}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _supaService = SupabaseService();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.deadline;
      _selectedTime = TimeOfDay.fromDateTime(widget.task!.deadline);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
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
    if (_titleController.text.isEmpty) return;

    final deadline = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      if (widget.task == null) {
        await _supaService.addTask(
          _titleController.text,
          _descriptionController.text,
          deadline,
        );
         // Schedule notification for new task
        await NotificationService().scheduleNotification(
          DateTime.now().microsecondsSinceEpoch, // Unique ID
          _titleController.text,
          deadline,
        );
      } else {
        await _supaService.updateTask(
          widget.task!.id,
          _titleController.text,
          _descriptionController.text,
          deadline,
          widget.task!.isCompleted,
        );
        // Reschedule notification for updated task
        await NotificationService().scheduleNotification(
          widget.task!.id,
          _titleController.text,
          deadline,
        );
      }
     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectDate,
                    ),
                    const Divider(),
                    ListTile(
                      title: Text('Time: ${_selectedTime.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: _selectTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.task == null ? 'Add Task' : 'Update Task',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}