import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:fitnora/services/user_session.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    // Set the local timezone from the device
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notifications',
          'Daily Notifications',
          channelDescription: 'Daily reminders for workout and meals',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> skipTodayNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    ).add(const Duration(days: 1)); // Skip today, start tomorrow

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notifications',
          'Daily Notifications',
          channelDescription: 'Daily reminders for workout and meals',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> markWorkoutDoneToday() async {
    final box = Hive.box(UserSession().settingsBoxName);
    final bool enabled = box.get('workout_enabled', defaultValue: true);
    if (!enabled) return;

    final timeStr = box.get('workout_time', defaultValue: '18:00');
    final time = _parseTime(timeStr);

    await skipTodayNotification(
      id: 1,
      title: "Workout Reminder",
      body: "Don't forget to complete your workout session today!",
      time: time,
    );
  }

  Future<void> markMealLoggedToday(String mealType) async {
    final box = Hive.box(UserSession().settingsBoxName);

    int id;
    String title;
    String body;
    String timeStr;

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        if (!(box.get('breakfast_enabled', defaultValue: true) as bool)) return;
        id = 2;
        title = "Breakfast Time";
        body = "Time to log your breakfast!";
        timeStr = box.get('breakfast_time', defaultValue: '08:30');
        break;
      case 'lunch':
        if (!(box.get('lunch_enabled', defaultValue: true) as bool)) return;
        id = 3;
        title = "Lunch Time";
        body = "Time to log your lunch!";
        timeStr = box.get('lunch_time', defaultValue: '13:00');
        break;
      case 'dinner':
        if (!(box.get('dinner_enabled', defaultValue: true) as bool)) return;
        id = 4;
        title = "Dinner Time";
        body = "Time to log your dinner!";
        timeStr = box.get('dinner_time', defaultValue: '20:00');
        break;
      case 'snack':
      case 'snacks':
        if (!(box.get('snack_enabled', defaultValue: true) as bool)) return;
        id = 5;
        title = "Snack Time";
        body = "Time to log your snacks!";
        timeStr = box.get('snack_time', defaultValue: '17:00');
        break;
      default:
        return;
    }

    final time = _parseTime(timeStr);

    await skipTodayNotification(
      id: id,
      title: title,
      body: body,
      time: time,
    );
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return const TimeOfDay(hour: 12, minute: 0);
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
