import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';

/// Stores the app's small local dataset on-device.
class StorageService {
  static const _medicinesKey = 'medicine_list';
  static const _doseLogsKey = 'dose_logs';
  static const _settingsKey = 'app_settings';
  Future<void> _writeQueue = Future<void>.value();

  Future<List<Medicine>> loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_medicinesKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Stored medicines are not a list.');
    }
    return decoded
        .map((entry) => Medicine.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
  }

  Future<void> saveMedicines(List<Medicine> medicines) async {
    await _write(_medicinesKey, () => jsonEncode(medicines.map((m) => m.toJson()).toList()));
  }

  Future<List<DoseLog>> loadDoseLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_doseLogsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Stored dose history is not a list.');
    }
    return decoded
        .map((entry) => DoseLog.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
  }

  Future<void> saveDoseLogs(List<DoseLog> logs) async {
    await _write(_doseLogsKey, () => jsonEncode(logs.map((log) => log.toJson()).toList()));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Stored app settings are not an object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> saveSettings({
    required String userName,
    required bool remindersEnabled,
    required int snoozeMinutes,
  }) async {
    await _write(
      _settingsKey,
      () => jsonEncode({
        'userName': userName,
        'remindersEnabled': remindersEnabled,
        'snoozeMinutes': snoozeMinutes,
      }),
    );
  }

  Future<void> _write(String key, String Function() encode) {
    final write = _writeQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, encode());
    });
    _writeQueue = write.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return write;
  }
}
