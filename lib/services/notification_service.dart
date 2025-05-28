import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'supabase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  NotificationService._() {
    _init();
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void _init() {
    tz.initializeTimeZones();
  }

  Future<void> rescheduleNotificationsAfterReboot() async {
    try {
      print('Rescheduling notifications after device reboot');
      // Inisialisasi waktu lokal (device)
      tz.initializeTimeZones();

      final tasks = await SupabaseService().getTasks();
      int rescheduledCount = 0;

      for (var task in tasks) {
        if (!task.isCompleted && task.deadline.isAfter(DateTime.now())) {
          // Buat ngecek kalau deadline masih di mas depan setelah hp di reboot
          final taskDeadline = tz.TZDateTime.from(task.deadline, tz.local);
          if (taskDeadline.isAfter(tz.TZDateTime.now(tz.local))) {
            await scheduleNotification(
              task.id,
              task.title,
              task.deadline,
            );
            rescheduledCount++;
          }
        }
      }

      print('Successfully rescheduled $rescheduledCount notifications');
      await checkPendingNotifications();
    } catch (e) {
      print('Error rescheduling notifications: $e');
      rethrow;
    }
  }

  Future<void> initNotification() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();

      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'task_deadline',
        'Task Deadlines',
        description: 'Notifications for task deadlines',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImplementation?.createNotificationChannel(channel);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize( // buat callback. jadi kalau user klik dialog notifnya, bisa membuka app dari situ
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification clicked: ${details.payload}');
      },
    );
    await rescheduleNotificationsAfterReboot();
  }

  Future<bool> checkNotificationPermissions() async {
    final bool? areNotificationsEnabled = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();

    print('Notifications enabled: $areNotificationsEnabled');
    return areNotificationsEnabled ?? false;
  }

  Future<void> scheduleNotification(int id, String title, DateTime deadline,
      {int minutesBefore = 15} // Menit default
      ) async {
    try {
      tz.initializeTimeZones();

      print(
          '\n------- Starting notification scheduling for task: $title (ID: $id) -------');

      if (!await checkNotificationPermissions()) {
        print('Warning: Notifications are not enabled!');
        return;
      }

      final localDeadline = tz.TZDateTime.from(deadline, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      if (localDeadline.isBefore(now)) {
        print(
            'Warning: Task deadline has already passed. Skipping notifications.');
        return;
      }

      await cancelTaskNotifications(id);

      final baseId = id * 1000;
      print('Scheduling with base ID: $baseId');
      print('Current time: $now');
      print('Task deadline: $localDeadline');
      print('Minutes before deadline: $minutesBefore');

      final scheduledTime =
          localDeadline.subtract(Duration(minutes: minutesBefore));

      if (scheduledTime.isBefore(now)) {
        print('Warning: Scheduled time has already passed');
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        'task_deadline',
        'Task Deadlines',
        channelDescription: 'Notifications for task deadlines',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        ongoing: true,
        autoCancel: false,
        channelShowBadge: true,
        additionalFlags: Int32List.fromList(<int>[4]),
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId,
        'Task Deadline Alert',
        'Task "$title" is due in $minutesBefore minutes',
        scheduledTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$title:$baseId',
      );

      print(
          'Successfully scheduled notification for $minutesBefore minutes before deadline');

      final pendingNotifications = await checkPendingNotifications();
      final verifiedCount = pendingNotifications
          .where((notification) => notification.id == baseId)
          .length;

      print('\nScheduling Summary:');
      print('- Successfully scheduled: $verifiedCount notification');
      print('- Total pending notifications: ${pendingNotifications.length}');
      print('----------------------------------------------------------\n');
    } catch (e) {
      print('Error scheduling notifications for task $title (ID: $id)');
      print('Error details: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> cancelNotification(int baseId) async { // buat cancel kalau tugasnya udah selesai
    try {
      print('Cancelling notifications for base ID: $baseId');

      await flutterLocalNotificationsPlugin.cancel(baseId);

      print('Successfully cancelled notifications for base ID: $baseId');
    } catch (e) {
      print('Error cancelling notifications: ${e.toString()}');
      rethrow;
    }
  }

// Lek tugsa udah selesai, fungsi ini jalan buat ga munculin notif
  Future<void> cancelTaskNotifications(int taskId) async {
    try {
      final baseId =
          taskId * 1000; //Pakai id generation yang sama seperti penjadwalan
      print(
          'Cancelling all notifications for task ID: $taskId (Base ID: $baseId)');

      await flutterLocalNotificationsPlugin.cancel(baseId);
      final pending = await checkPendingNotifications();
      print('Remaining notifications after cancellation: ${pending.length}');
    } catch (e) {
      print('Error cancelling task notifications: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<PendingNotificationRequest>> checkPendingNotifications() async {
    try {
      final pending =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('Pending notifications: ${pending.length}');
      for (var notification in pending) {
        print('ID: ${notification.id}, Title: ${notification.title}');
      }
      return pending;
    } catch (e) {
      print('Error checking pending notifications: ${e.toString()}');
      return [];
    }
  }
}
