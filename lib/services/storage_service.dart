import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';

/// Handles saving and loading the medicine list on the device.
/// Uses shared_preferences so no backend or database setup is needed.
class StorageService {
  static const _key = 'medicine_list';

  Future<List<Medicine>> loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Medicine.fromJson(e)).toList();
  }

  Future<void> saveMedicines(List<Medicine> medicines) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(medicines.map((m) => m.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
