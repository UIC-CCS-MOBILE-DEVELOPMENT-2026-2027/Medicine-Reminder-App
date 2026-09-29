import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'notification_service.dart';

/// In-memory app state shared by all screens (no extra packages needed).
class MedicineStore extends ChangeNotifier {
  MedicineStore._() {
    _seed();
  }
  static final MedicineStore instance = MedicineStore._();

  final List<Medicine> _medicines = [];
  final List<DoseLog> _logs = [];

  String userName = 'Friend';
  bool remindersEnabled = true;
  int snoozeMinutes = 10;

  List<Medicine> get medicines => List.unmodifiable(_medicines);

  Medicine? byId(String id) {
    for (final m in _medicines) {
      if (m.id == id) return m;
    }
    return null;
  }

  // ---- Medicines ----------------------------------------------------------

  void addMedicine(Medicine m) {
    _medicines.add(m);
    _sync(m);
    notifyListeners();
  }

  void updateMedicine(Medicine m) {
    _dropPending(m.id);
    _sync(m);
    notifyListeners();
  }

  void toggleActive(Medicine m) {
    m.active = !m.active;
    _dropPending(m.id);
    _sync(m);
    notifyListeners();
  }

  void deleteMedicine(String id) {
    _medicines.removeWhere((m) => m.id == id);
    _logs.removeWhere((l) => l.medicineId == id);
    NotificationService().cancelForMedicine(id);
    notifyListeners();
  }

  void _dropPending(String id) =>
      _logs.removeWhere((l) => l.medicineId == id && l.status == DoseStatus.pending);

  void _sync(Medicine m) {
    if (remindersEnabled && m.active) {
      NotificationService().scheduleForMedicine(m);
    } else {
      NotificationService().cancelForMedicine(m.id);
    }
  }

  // ---- Doses & history ----------------------------------------------------

  List<DoseLog> dosesForToday() {
    final now = DateTime.now();
    final result = <DoseLog>[];
    for (final m in _medicines.where((m) => m.active)) {
      for (final t in m.times) {
        final scheduled = DateTime(now.year, now.month, now.day, t.hour, t.minute);
        DoseLog? log;
        for (final l in _logs) {
          if (l.medicineId == m.id && l.scheduled == scheduled) {
            log = l;
            break;
          }
        }
        if (log == null) {
          log = DoseLog(
            medicineId: m.id,
            medicineName: m.name,
            dosage: m.dosage,
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

  void markDose(DoseLog log, DoseStatus status) {
    log.status = status;
    log.loggedAt = DateTime.now();
    notifyListeners();
  }

  void undoDose(DoseLog log) {
    log.status = DoseStatus.pending;
    log.loggedAt = null;
    notifyListeners();
  }

  List<DoseLog> history({String? medicineId}) {
    final list = _logs
        .where((l) => l.status != DoseStatus.pending && (medicineId == null || l.medicineId == medicineId))
        .toList()
      ..sort((a, b) => b.scheduled.compareTo(a.scheduled));
    return list;
  }

  /// Fraction of logged doses that were taken (0..1).
  double get adherence {
    final h = history();
    if (h.isEmpty) return 0;
    return h.where((l) => l.status == DoseStatus.taken).length / h.length;
  }

  void clearHistory() {
    _logs.removeWhere((l) => l.status != DoseStatus.pending);
    notifyListeners();
  }

  // ---- Settings -----------------------------------------------------------

  void updateSettings({String? name, bool? reminders, int? snooze}) {
    if (name != null) userName = name.trim().isEmpty ? 'Friend' : name.trim();
    if (snooze != null) snoozeMinutes = snooze;
    if (reminders != null && reminders != remindersEnabled) {
      remindersEnabled = reminders;
      for (final m in _medicines) {
        _sync(m);
      }
    }
    notifyListeners();
  }

  // ---- Demo data ----------------------------------------------------------

  void _seed() {
    final vitD = Medicine(
      id: 'seed1',
      name: 'Vitamin D',
      dosage: '1000 IU',
      form: 'Capsule',
      times: const [TimeOfDay(hour: 8, minute: 0)],
      notes: 'Take with breakfast.',
    );
    final amox = Medicine(
      id: 'seed2',
      name: 'Amoxicillin',
      dosage: '500 mg',
      form: 'Capsule',
      times: const [TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 21, minute: 0)],
      notes: 'Finish the full course.',
    );
    final para = Medicine(
      id: 'seed3',
      name: 'Paracetamol',
      dosage: '500 mg',
      form: 'Tablet',
      times: const [TimeOfDay(hour: 14, minute: 0)],
    );
    _medicines.addAll([vitD, amox, para]);

    final now = DateTime.now();
    for (var d = 1; d <= 3; d++) {
      final day = now.subtract(Duration(days: d));
      for (final m in _medicines) {
        for (final t in m.times) {
          final scheduled = DateTime(day.year, day.month, day.day, t.hour, t.minute);
          final skipped = (d + t.hour) % 5 == 0;
          _logs.add(DoseLog(
            medicineId: m.id,
            medicineName: m.name,
            dosage: m.dosage,
            scheduled: scheduled,
            status: skipped ? DoseStatus.skipped : DoseStatus.taken,
            loggedAt: scheduled.add(const Duration(minutes: 5)),
          ));
        }
      }
    }
  }
}
