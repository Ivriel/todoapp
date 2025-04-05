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
      // Ensure timezone is initialized
      tz.initializeTimeZones();

      final tasks = await SupabaseService().getTasks();
      int rescheduledCount = 0;

      for (var task in tasks) {
        if (!task.isCompleted && task.deadline.isAfter(DateTime.now())) {
          // Check if deadline is still in future after reboot
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
      // Print additional debug info
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

    await flutterLocalNotificationsPlugin.initialize(
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

 Future<void> scheduleNotification(int id, String title, DateTime deadline) async {
  try {
    // Force timezone initialization
    tz.initializeTimeZones();
    
    print('\n------- Starting notification scheduling for task: $title (ID: $id) -------');
    
    // Check permissions first
    if (!await checkNotificationPermissions()) {
      print('Warning: Notifications are not enabled!');
      return;
    }

    // Convert to local timezone for accurate comparisons
    final localDeadline = tz.TZDateTime.from(deadline, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    // Verify deadline is in the future
    if (localDeadline.isBefore(now)) {
      print('Warning: Task deadline has already passed. Skipping notifications.');
      return;
    }

    // Cancel any existing notifications before scheduling new ones
    await cancelTaskNotifications(id);

    // Generate unique base ID for this task's notifications
    final baseId = id * 1000;
    print('Scheduling with base ID: $baseId');
    print('Current time: $now');
    print('Task deadline: $localDeadline');

    final notificationTimes = [
      const Duration(minutes: 15),
      const Duration(minutes: 10),
      const Duration(minutes: 5),
    ];

    int scheduledCount = 0;
    for (var i = 0; i < notificationTimes.length; i++) {
      final scheduledTime = localDeadline.subtract(notificationTimes[i]);

      if (scheduledTime.isBefore(now)) {
        print('Skipping ${notificationTimes[i].inMinutes} minute notification: Already passed');
        continue;
      }

      final notificationId = baseId + i;

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
        additionalFlags: Int32List.fromList(<int>[4]), // Insistent flag
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Task Deadline Alert',
        'Task "$title" is due in ${notificationTimes[i].inMinutes} minutes',
        scheduledTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$title:$notificationId',
      );

      scheduledCount++;
      print('Successfully scheduled notification ID: $notificationId for ${notificationTimes[i].inMinutes} minutes before deadline');
    }

    // Verify scheduling was successful
    final pendingNotifications = await checkPendingNotifications();
    final verifiedCount = pendingNotifications
        .where((notification) => notification.id >= baseId && notification.id < baseId + 3)
        .length;

    print('\nScheduling Summary:');
    print('- Attempted to schedule: ${notificationTimes.length} notifications');
    print('- Successfully scheduled: $scheduledCount notifications');
    print('- Verified pending: $verifiedCount notifications');
    print('- Total pending notifications: ${pendingNotifications.length}');
    print('----------------------------------------------------------\n');

  } catch (e) {
    print('Error scheduling notifications for task $title (ID: $id)');
    print('Error details: ${e.toString()}');
    print('Stack trace: ${StackTrace.current}');
    rethrow;
  }
}
  Future<void> cancelNotification(int baseId) async {
    try {
      print('Cancelling notifications for base ID: $baseId');
      // Cancel all possible notifications for this task
      for (var i = 0; i < 5; i++) {
        await flutterLocalNotificationsPlugin.cancel(baseId + i);
      }
      print('Successfully cancelled notifications for base ID: $baseId');
    } catch (e) {
      print('Error cancelling notifications: ${e.toString()}');
      rethrow;
    }
  }

// Add this method after cancelNotification
  Future<void> cancelTaskNotifications(int taskId) async {
    try {
      final baseId = taskId * 1000; // Use same ID generation as scheduling
      print(
          'Cancelling all notifications for task ID: $taskId (Base ID: $baseId)');

      // Cancel notifications for all time intervals (15, 10, 5 minutes)
      for (var i = 0; i < 3; i++) {
        await flutterLocalNotificationsPlugin.cancel(baseId + i);
      }

      // Verify cancellation
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
