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
          
      await androidImplementation?.requestNotificationsPermission();
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
      // Multiple notification times for redundancy
      final notificationTimes = [
        const Duration(minutes: 15),  // First alert
        const Duration(minutes: 10),  // Main alert
        const Duration(minutes: 5),   // Final reminder
      ];

      for (var i = 0; i < notificationTimes.length; i++) {
        final scheduledTime = tz.TZDateTime.from(deadline, tz.local)
            .subtract(notificationTimes[i]);
        
        if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
          print('Skipping notification at ${notificationTimes[i].inMinutes} minutes: Already passed');
          continue;
        }

        const androidDetails = AndroidNotificationDetails(
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
        );

        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + i,  // Unique ID for each notification
          'Task Deadline Alert',
          'Task "$title" is due in ${notificationTimes[i].inMinutes} minutes',
          scheduledTime,
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: title,
        );
        
        print('Scheduled notification for "$title" at: $scheduledTime (${notificationTimes[i].inMinutes} min before)');
      }

      // Add debug information
      print('Current time: ${tz.TZDateTime.now(tz.local)}');
      print('Device timezone: ${tz.local}');
      print('Task deadline: $deadline');
      
    } catch (e) {
      print('Error scheduling notification: $e');
      print('Error details: ${e.toString()}');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      // Cancel all notifications for this task (including multiple alerts)
      for (var i = 0; i < 3; i++) {
        await flutterLocalNotificationsPlugin.cancel(id + i);
      }
      print('All notifications cancelled for task id: $id');
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