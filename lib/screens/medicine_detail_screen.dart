import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/medicine_store.dart';
import '../utils.dart';
import 'add_medicine_screen.dart';

/// Screen 3 - Medicine details: schedule, notes, pause/resume, edit, delete.
class MedicineDetailScreen extends StatelessWidget {
  const MedicineDetailScreen({super.key, required this.medicineId});
  final String medicineId;

  @override
  Widget build(BuildContext context) {
    final store = MedicineStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final m = store.byId(medicineId);
        if (m == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Medicine not found')));
        }
        final recent = store.history(medicineId: m.id).take(5).toList();
        final cs = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(m.name),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => pushPage(context, AddMedicineScreen(medicine: m)),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, m),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 28, child: Icon(m.icon, size: 30)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: Theme.of(context).textTheme.titleLarge),
                            Text('${m.dosage} \u2022 ${m.form}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Reminders active'),
                subtitle: Text(m.active ? 'You will be reminded daily' : 'Paused'),
                value: m.active,
                onChanged: (_) => store.toggleActive(m),
              ),
              const SizedBox(height: 8),
              Text('Daily reminder times', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in m.times)
                    Chip(avatar: const Icon(Icons.alarm, size: 18), label: Text(t.format(context))),
                ],
              ),
              if (m.notes.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(m.notes),
              ],
              const SizedBox(height: 20),
              Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Nothing logged yet.'),
                )
              else
                for (final l in recent)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      l.status == DoseStatus.taken ? Icons.check_circle : Icons.remove_circle_outline,
                      color: l.status == DoseStatus.taken ? Colors.green : cs.outline,
                    ),
                    title: Text(l.status == DoseStatus.taken ? 'Taken' : 'Skipped'),
                    subtitle: Text(
                      '${dayLabel(l.scheduled)} at ${TimeOfDay.fromDateTime(l.scheduled).format(context)}',
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Medicine m) async {
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text('${m.name} and its history will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      MedicineStore.instance.deleteMedicine(m.id);
      navigator.pop();
    }
  }
}
