import 'package:flutter/foundation.dart';
import '../models/medicine.dart';

/// Placeholder notification layer so the app runs with zero platform setup.
///
/// To send real reminders, add `flutter_local_notifications` + `timezone`
/// to pubspec.yaml and replace the bodies below with zonedSchedule(...)
/// calls (one repeating daily notification per TimeOfDay).
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  Future<void> init() async {
    debugPrint('[Notifications] initialised');
  }

  Future<void> scheduleForMedicine(Medicine m) async {
    await cancelForMedicine(m.id);
    for (final t in m.times) {
      debugPrint('[Notifications] schedule ${m.name} daily at ${t.hour}:${t.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> cancelForMedicine(String medicineId) async {
    debugPrint('[Notifications] cancel reminders for $medicineId');
  }
}
