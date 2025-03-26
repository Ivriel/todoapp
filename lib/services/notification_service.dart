import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

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

  Future<void> initNotification() async {
    if (Platform.isAndroid) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      await androidImplementation?.requestNotificationsPermission();  // Changed this line
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification clicked: ${details.payload}');
      },
    );
  }

  Future<void> scheduleNotification(int id, String title, DateTime deadline) async {
    try {
      final scheduledTime = tz.TZDateTime.from(deadline, tz.local)
          .subtract(const Duration(minutes: 10));
      
      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        print('Skipping notification - time has passed: $scheduledTime');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'task_deadline',  // channel id
        'Task Deadlines', // channel name
        channelDescription: 'Notifications for task deadlines',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        actions: [
          AndroidNotificationAction('mark_done', 'Mark as Done'),
          AndroidNotificationAction('snooze', 'Snooze 5 minutes'),
        ],
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Deadline Approaching!',
        'Task "$title" is due in 10 minutes',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: title,
      );
      
      print('Notification scheduled for task "$title" at: $scheduledTime');
    } catch (e) {
      print('Error scheduling notification: $e');
      print('Error details: ${e.toString()}');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      print('Notification cancelled for id: $id');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }
}