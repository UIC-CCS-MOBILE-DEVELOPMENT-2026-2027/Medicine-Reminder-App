// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medminder/main.dart';
import 'package:medminder/models/medicine.dart';

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
}
