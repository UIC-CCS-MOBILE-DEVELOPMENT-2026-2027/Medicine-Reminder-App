import 'package:flutter/material.dart';

import '../models/medicine.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class MedicineStore extends ChangeNotifier {
  MedicineStore._();
  static final MedicineStore instance = MedicineStore._();

  final StorageService _storage = StorageService();
  final List<Medicine> _medicines = [];
  final List<DoseLog> _logs = [];
  bool _initialized = false;

  String userName = 'Friend';
  bool remindersEnabled = true;
  int snoozeMinutes = 10;

  List<Medicine> get medicines => List.unmodifiable(_medicines);

  Future<void> initialize() async {
    if (_initialized) return;

    final medicines = await _storage.loadMedicines();
    final logs = await _storage.loadDoseLogs();
    final settings = await _storage.loadSettings();

    _medicines
      ..clear()
      ..addAll(medicines);
    _logs
      ..clear()
      ..addAll(logs);
    userName = settings['userName'] as String? ?? 'Friend';
    remindersEnabled = settings['remindersEnabled'] as bool? ?? true;
    snoozeMinutes = settings['snoozeMinutes'] as int? ?? 10;
    _initialized = true;

    for (final medicine in _medicines) {
      await _sync(medicine);
    }
    notifyListeners();
  }

  Medicine? byId(String id) {
    for (final medicine in _medicines) {
      if (medicine.id == id) return medicine;
    }
    return null;
  }

  Future<void> addMedicine(Medicine medicine) async {
    _medicines.add(medicine);
    notifyListeners();
    await _storage.saveMedicines(_medicines);
    await _sync(medicine);
  }

  Future<void> updateMedicine(Medicine medicine) async {
    _dropPending(medicine.id);
    notifyListeners();
    await _storage.saveMedicines(_medicines);
    await _storage.saveDoseLogs(_logs);
    await _sync(medicine);
  }

  Future<void> toggleActive(Medicine medicine) async {
    medicine.active = !medicine.active;
    _dropPending(medicine.id);
    notifyListeners();
    await _storage.saveMedicines(_medicines);
    await _storage.saveDoseLogs(_logs);
    await _sync(medicine);
  }

  Future<void> deleteMedicine(String id) async {
    _medicines.removeWhere((medicine) => medicine.id == id);
    _logs.removeWhere((log) => log.medicineId == id);
    notifyListeners();
    await _storage.saveMedicines(_medicines);
    await _storage.saveDoseLogs(_logs);
    await NotificationService().cancelForMedicine(id);
  }

  void _dropPending(String id) =>
      _logs.removeWhere((log) => log.medicineId == id && log.status == DoseStatus.pending);

  Future<void> _sync(Medicine medicine) async {
    if (remindersEnabled && medicine.active) {
      await NotificationService().scheduleForMedicine(medicine);
    } else {
      await NotificationService().cancelForMedicine(medicine.id);
    }
  }

  List<DoseLog> dosesForToday() {
    final now = DateTime.now();
    final result = <DoseLog>[];
    for (final medicine in _medicines.where((medicine) => medicine.active)) {
      for (final time in medicine.times) {
        final scheduled =
            DateTime(now.year, now.month, now.day, time.hour, time.minute);
        DoseLog? log;
        for (final existingLog in _logs) {
          if (existingLog.medicineId == medicine.id &&
              existingLog.scheduled == scheduled) {
            log = existingLog;
            break;
          }
        }
        if (log == null) {
          log = DoseLog(
            medicineId: medicine.id,
            medicineName: medicine.name,
            dosage: medicine.dosage,
            scheduled: scheduled,
          );
          _logs.add(log);
        }
        result.add(log);
      }
    }
    result.sort((a, b) => a.scheduled.compareTo(b.scheduled));
    return result;
  }

  Future<void> markDose(DoseLog log, DoseStatus status) async {
    log.status = status;
    log.loggedAt = DateTime.now();
    notifyListeners();
    await _storage.saveDoseLogs(_logs);
  }

  Future<void> undoDose(DoseLog log) async {
    log.status = DoseStatus.pending;
    log.loggedAt = null;
    notifyListeners();
    await _storage.saveDoseLogs(_logs);
  }

  List<DoseLog> history({String? medicineId}) {
    final list = _logs
        .where((log) =>
            log.status != DoseStatus.pending &&
            (medicineId == null || log.medicineId == medicineId))
        .toList()
      ..sort((a, b) => b.scheduled.compareTo(a.scheduled));
    return list;
  }

  double get adherence {
    final loggedDoses = history();
    if (loggedDoses.isEmpty) return 0;
    return loggedDoses
            .where((log) => log.status == DoseStatus.taken)
            .length /
        loggedDoses.length;
  }

  Future<void> clearHistory() async {
    _logs.removeWhere((log) => log.status != DoseStatus.pending);
    notifyListeners();
    await _storage.saveDoseLogs(_logs);
  }

  Future<void> updateSettings({
    String? name,
    bool? reminders,
    int? snooze,
  }) async {
    if (name != null) {
      userName = name.trim().isEmpty ? 'Friend' : name.trim();
    }
    if (snooze != null) snoozeMinutes = snooze;
    final remindersChanged = reminders != null && reminders != remindersEnabled;
    if (reminders != null) remindersEnabled = reminders;
    notifyListeners();

    await _storage.saveSettings(
      userName: userName,
      remindersEnabled: remindersEnabled,
      snoozeMinutes: snoozeMinutes,
    );
    if (remindersChanged) {
      for (final medicine in _medicines) {
        await _sync(medicine);
      }
    }
  }
}
