import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../models/medicine.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _channelId = 'medicine_reminders';
  static const _channelName = 'Medicine reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionRequested = false;

  bool get _supportsScheduledNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (_initialized || !_supportsScheduledNotifications) return;

    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized == false) {
      throw StateError('The local notification plugin failed to initialize.');
    }
    _initialized = true;
  }

  Future<void> scheduleForMedicine(Medicine medicine) async {
    if (!_supportsScheduledNotifications || !_initialized) return;

    await cancelForMedicine(medicine.id);
    await _requestPermissions();

    final now = timezone.TZDateTime.now(timezone.local);
    for (final time in medicine.times) {
      var scheduled = timezone.TZDateTime(
        timezone.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = timezone.TZDateTime(
          timezone.local,
          now.year,
          now.month,
          now.day + 1,
          time.hour,
          time.minute,
        );
      }

      await _plugin.zonedSchedule(
        id: _notificationId(medicine.id, time),
        title: 'Time to take ${medicine.name}',
        body: medicine.dosage,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Daily medicine dose reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medicine.id,
      );
    }
  }

  Future<void> cancelForMedicine(String medicineId) async {
    if (!_supportsScheduledNotifications || !_initialized) return;

    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      if (notification.payload == medicineId) {
        await _plugin.cancel(id: notification.id);
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (_permissionRequested) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    _permissionRequested = true;
  }

  int _notificationId(String medicineId, TimeOfDay time) {
    final value = '$medicineId:${time.hour}:${time.minute}';
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
