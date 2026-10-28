// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medminder/main.dart';
import 'package:medminder/models/medicine.dart';
import 'package:medminder/services/medicine_store.dart';
import 'package:medminder/services/storage_service.dart';

void main() {
  testWidgets('app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicineReminderApp());

    expect(find.text('Hello, Friend'), findsOneWidget);
    expect(find.text("Today's schedule"), findsOneWidget);
  });

  test('medicine model supports reminderTimes and JSON serialization', () {
    final medicine = Medicine(
      id: 'm1',
      name: 'Vitamin D',
      dosage: '1000 IU',
      reminderTimes: const [TimeOfDay(hour: 8, minute: 0)],
      isActive: true,
    );

    expect(medicine.times, hasLength(1));
    expect(medicine.isActive, isTrue);
    expect(medicine.toJson()['name'], 'Vitamin D');
    expect(Medicine.fromJson(medicine.toJson()).id, 'm1');
  });

  test(
    'local storage round-trips medicines, dose history, and settings',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      final medicine = Medicine(
        id: 'm1',
        name: 'Vitamin D',
        dosage: '1000 IU',
        times: const [TimeOfDay(hour: 8, minute: 0)],
      );
      final dose = DoseLog(
        medicineId: 'm1',
        medicineName: 'Vitamin D',
        dosage: '1000 IU',
        scheduled: DateTime(2026, 10, 29, 8),
        status: DoseStatus.taken,
        loggedAt: DateTime(2026, 10, 29, 8, 2),
      );

      await storage.saveMedicines([medicine]);
      await storage.saveDoseLogs([dose]);
      await storage.saveSettings(
        userName: 'Alex',
        remindersEnabled: false,
        snoozeMinutes: 15,
      );

      expect(
        (await storage.loadMedicines()).single.toJson(),
        medicine.toJson(),
      );
      expect((await storage.loadDoseLogs()).single.toJson(), dose.toJson());
      expect(await storage.loadSettings(), {
        'userName': 'Alex',
        'remindersEnabled': false,
        'snoozeMinutes': 15,
      });
    },
  );

  test('medicine store restores saved state on initialization', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    final medicine = Medicine(
      id: 'm2',
      name: 'Daily tablet',
      dosage: '1 tablet',
      times: const [TimeOfDay(hour: 9, minute: 30)],
    );
    final dose = DoseLog(
      medicineId: 'm2',
      medicineName: 'Daily tablet',
      dosage: '1 tablet',
      scheduled: DateTime(2026, 10, 28, 9, 30),
      status: DoseStatus.skipped,
    );
    await storage.saveMedicines([medicine]);
    await storage.saveDoseLogs([dose]);
    await storage.saveSettings(
      userName: 'Jordan',
      remindersEnabled: false,
      snoozeMinutes: 5,
    );

    final store = MedicineStore.instance;
    await store.initialize();

    expect(store.medicines.single.name, 'Daily tablet');
    expect(store.history().single.status, DoseStatus.skipped);
    expect(store.userName, 'Jordan');
    expect(store.remindersEnabled, isFalse);
    expect(store.snoozeMinutes, 5);
  });
}
