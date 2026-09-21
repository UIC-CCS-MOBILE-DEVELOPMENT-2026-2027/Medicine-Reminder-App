import 'package:flutter/material.dart';

/// Represents one medicine entry with its reminder times.
class Medicine {
  final String id;
  String name;
  String dosage; // e.g. "500mg" or "1 tablet"
  String notes;
  List<TimeOfDay> reminderTimes;
  bool isActive;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    this.notes = '',
    required this.reminderTimes,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'notes': notes,
      'reminderTimes': reminderTimes
          .map((t) => '${t.hour}:${t.minute}')
          .toList(),
      'isActive': isActive,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      notes: json['notes'] ?? '',
      reminderTimes: (json['reminderTimes'] as List)
          .map((s) {
            final parts = (s as String).split(':');
            return TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          })
          .toList(),
      isActive: json['isActive'] ?? true,
    );
  }
}
