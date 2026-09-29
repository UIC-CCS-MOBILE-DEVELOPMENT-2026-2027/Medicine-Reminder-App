import 'package:flutter/material.dart';

class Medicine {
  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    List<TimeOfDay>? times,
    List<TimeOfDay>? reminderTimes,
    this.form = 'Tablet',
    this.notes = '',
    bool? active,
    bool? isActive,
  })  : times = List<TimeOfDay>.from(times ?? reminderTimes ?? const []),
        active = active ?? isActive ?? true;

  factory Medicine.fromJson(Map<String, dynamic> json) {
    final rawTimes = json['reminderTimes'] ?? json['times'] ?? const <dynamic>[];
    final times = (rawTimes as List<dynamic>?)
            ?.map((entry) {
              if (entry is Map<String, dynamic>) {
                final hour = entry['hour'] as int? ?? 0;
                final minute = entry['minute'] as int? ?? 0;
                return TimeOfDay(hour: hour, minute: minute);
              }
              return const TimeOfDay(hour: 0, minute: 0);
            })
            .toList() ??
        <TimeOfDay>[];

    return Medicine(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      times: times,
      form: json['form']?.toString() ?? 'Tablet',
      notes: json['notes']?.toString() ?? '',
      active: json['active'] as bool? ?? json['isActive'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? json['active'] as bool? ?? true,
    );
  }

  final String id;
  String name;
  String dosage;
  String form;
  String notes;
  bool active;
  List<TimeOfDay> times;

  List<TimeOfDay> get reminderTimes => times;
  set reminderTimes(List<TimeOfDay> value) => times = List<TimeOfDay>.from(value);

  bool get isActive => active;
  set isActive(bool value) => active = value;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'form': form,
      'notes': notes,
      'active': active,
      'isActive': active,
      'reminderTimes': times
          .map((time) => {'hour': time.hour, 'minute': time.minute})
          .toList(),
      'times': times
          .map((time) => {'hour': time.hour, 'minute': time.minute})
          .toList(),
    };
  }

  IconData get icon {
    switch (form) {
      case 'Liquid':
        return Icons.water_drop_outlined;
      case 'Injection':
        return Icons.vaccines_outlined;
      case 'Drops':
        return Icons.opacity;
      case 'Capsule':
        return Icons.medication_liquid_outlined;
      default:
        return Icons.medication_outlined;
    }
  }
}

enum DoseStatus { pending, taken, skipped }

class DoseLog {
  DoseLog({
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.scheduled,
    this.status = DoseStatus.pending,
    this.loggedAt,
  });

  final String medicineId;
  final String medicineName;
  final String dosage;
  final DateTime scheduled;
  DoseStatus status;
  DateTime? loggedAt;
}
