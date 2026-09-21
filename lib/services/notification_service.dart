import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/medicine.dart';

/// Wraps flutter_local_notifications so the rest of the app only has to
/// call simple methods like scheduleForMedicine() and cancelForMedicine().
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Android 13+ requires runtime notification permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Each reminder time for a medicine gets its own notification id so it
  /// can be individually scheduled or cancelled. We derive stable ids from
  /// the medicine id's hashcode plus the index of the time slot.
  int _notificationId(String medicineId, int timeIndex) {
    return (medicineId.hashCode & 0x7fffffff) + timeIndex;
  }

  Future<void> scheduleForMedicine(Medicine medicine) async {
    // Clear any existing schedule for this medicine first, in case times
    // or the active flag changed.
    await cancelForMedicine(medicine);
    if (!medicine.isActive) return;

    for (int i = 0; i < medicine.reminderTimes.length; i++) {
      final time = medicine.reminderTimes[i];
      final scheduledDate = _nextInstanceOfTime(time);

      await _plugin.zonedSchedule(
        id: _notificationId(medicine.id, i),
        title: 'Time to take ${medicine.name}',
        body: medicine.dosage.isNotEmpty
            ? 'Dosage: ${medicine.dosage}'
            : 'Reminder',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminder_channel',
            'Medicine Reminders',
            channelDescription: 'Reminders to take your medicine on time',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelForMedicine(Medicine medicine) async {
    for (int i = 0; i < medicine.reminderTimes.length; i++) {
      await _plugin.cancel(id: _notificationId(medicine.id, i));
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
