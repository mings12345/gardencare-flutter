import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize timezone database
    tz.initializeTimeZones();
    
    // Set default timezone
    tz.setLocalLocation(tz.getLocation('Asia/Manila')); // Replace with your preferred timezone

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'plant_reminder_channel',
      'Plant Reminders',
      importance: Importance.max,
    );
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    _isInitialized = true;
  }

  static Future<bool> get canScheduleExactAlarms async {
  final androidPlugin = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
    AndroidFlutterLocalNotificationsPlugin>();
  return await androidPlugin?.canScheduleExactNotifications() ?? false;
}

  static Future<void> scheduleWaterReminder({
  required int id,
  required String plantName,
  required int repeatDays,
}) async {
  // Ensure initialization
  if (!_isInitialized) {
    await initialize();
  }
  
  try {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Water Your Plant',
      "It's time to water your $plantName 🌱",
      _nextInstanceOfDays(repeatDays),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'plant_reminder_channel',
          'Plant Reminders',
          importance: Importance.max,
          priority: Priority.high,
          channelDescription: 'Reminders for plant care',
        ),
      ),
      // Try exact scheduling first, but be prepared to fall back
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  } on PlatformException catch (e) {
    if (e.code == 'exact_alarms_not_permitted') {
      // Fall back to inexact scheduling if exact alarms aren't permitted
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Water Your Plant',
        "It's time to water your $plantName 🌱",
        _nextInstanceOfDays(repeatDays),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'plant_reminder_channel',
            'Plant Reminders',
            importance: Importance.max,
            priority: Priority.high,
            channelDescription: 'Reminders for plant care',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      print('Error scheduling notification: $e');
      rethrow;
    }
  } catch (e) {
    print('Error scheduling notification: $e');
    rethrow;
  }
}

  static tz.TZDateTime _nextInstanceOfDays(int daysInterval) {
    try {
      return tz.TZDateTime.now(tz.local).add(Duration(minutes: 1));
    } catch (e) {
      print('Error calculating next instance: $e');
      // Create a DateTime for the current time plus daysInterval
      final DateTime now = DateTime.now();
      final DateTime scheduledDate = DateTime(
        now.year,
        now.month,
        now.day + daysInterval,
        8, // 8 AM
        0, // 0 minutes
      );
      
      // Convert to TZDateTime using from()
      return tz.TZDateTime.from(scheduledDate, tz.local);
    }
  }
}