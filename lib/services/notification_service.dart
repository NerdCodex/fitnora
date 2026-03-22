import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:fitnora/services/user_session.dart';
import 'package:fitnora/services/workout_db_service.dart';

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
    // We schedule 7 days of individual alarms instead of using 
    // DateTimeComponents.time, because DateTimeComponents ignores the "skip" date
    // and fires today anyway if the time hasn't passed.
    await cancelNotification(id);
    
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    
    for (int i = 0; i < 7; i++) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        // Use a unique ID for each day so they don't overwrite
        id: id + (i * 100), 
        title: title,
        body: body,
        scheduledDate: scheduledDate.add(Duration(days: i)),
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
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    // Cancel the base ID and the 7-day future IDs
    await flutterLocalNotificationsPlugin.cancel(id: id);
    for (int i = 0; i < 7; i++) {
      await flutterLocalNotificationsPlugin.cancel(id: id + (i * 100));
    }
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
    await cancelNotification(id);
    
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    ).add(const Duration(days: 1)); // Skip today, start tomorrow

    // Schedule 7 days out, starting tomorrow
    for (int i = 0; i < 7; i++) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id + (i * 100),
        title: title,
        body: body,
        scheduledDate: scheduledDate.add(Duration(days: i)),
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
      );
    }
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

  /// Call on app startup (after user is logged in and DB is ready).
  /// Checks what the user has already logged today and skips
  /// today's notification for those items so they don't fire.
  Future<void> syncNotificationsWithToday() async {
    try {
      final db = WorkoutDatabaseService.instance;

      // 1. Check workout — skip today's reminder if already done
      if (await db.hasTodayWorkout()) {
        await markWorkoutDoneToday();
      }

      // 2. Check meals — skip today's reminder for each logged meal type
      final loggedMeals = await db.getTodayMealTypes();
      for (final mealType in loggedMeals) {
        await markMealLoggedToday(mealType);
      }
    } catch (e) {
      debugPrint('Notification sync error: $e');
    }
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
