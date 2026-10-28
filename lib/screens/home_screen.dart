import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../services/medicine_store.dart';
import '../utils.dart';
import 'add_medicine_screen.dart';
import 'history_screen.dart';
import 'medicine_detail_screen.dart';
import 'medicine_list_screen.dart';
import 'settings_screen.dart';

/// Screen 1 - Home dashboard: today's doses + entry point to every other screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicineStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final doses = store.dosesForToday();
        final taken = doses.where((d) => d.status == DoseStatus.taken).length;
        final pending = doses
            .where((d) => d.status == DoseStatus.pending)
            .length;
        final progress = doses.isEmpty ? 0.0 : taken / doses.length;
        final cs = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text('Hello, ${store.userName}'),
            actions: [
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => pushPage(context, const SettingsScreen()),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Card(
                color: cs.primaryContainer,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 84,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 9,
                                backgroundColor: cs.surface,
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatDate(DateTime.now()),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$taken of ${doses.length} doses taken',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text('$pending remaining today'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.medication_outlined,
                    label: 'Medicines',
                    onTap: () => pushPage(context, const MedicineListScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () => pushPage(context, const HistoryScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => pushPage(context, const SettingsScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Today's schedule",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (doses.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 40,
                          color: cs.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No doses scheduled',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add a medicine to create your daily reminder schedule.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final d in doses) _DoseCard(dose: d),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => pushPage(context, const AddMedicineScreen()),
            icon: const Icon(Icons.add),
            label: const Text('Add medicine'),
          ),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 88,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({required this.dose});
  final DoseLog dose;

  @override
  Widget build(BuildContext context) {
    final store = MedicineStore.instance;
    final time = TimeOfDay.fromDateTime(dose.scheduled).format(context);
    final cs = Theme.of(context).colorScheme;

    Widget action;
    IconData leading;
    Color leadingColor;
    String status;
    switch (dose.status) {
      case DoseStatus.taken:
        leading = Icons.check_circle;
        leadingColor = const Color(0xFF176B43);
        status = 'Taken';
        action = TextButton(
          onPressed: () => store.undoDose(dose),
          child: const Text('Undo'),
        );
        break;
      case DoseStatus.skipped:
        leading = Icons.remove_circle;
        leadingColor = cs.onSurfaceVariant;
        status = 'Skipped';
        action = TextButton(
          onPressed: () => store.undoDose(dose),
          child: const Text('Undo'),
        );
        break;
      case DoseStatus.pending:
        leading = Icons.schedule;
        leadingColor = cs.primary;
        status = 'Due at $time';
        action = Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => store.markDose(dose, DoseStatus.skipped),
                icon: const Icon(Icons.close),
                label: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => store.markDose(dose, DoseStatus.taken),
                icon: const Icon(Icons.check),
                label: const Text('Taken'),
              ),
            ),
          ],
        );
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(leading, color: leadingColor, size: 32),
              title: Text(dose.medicineName),
              subtitle: Text('${dose.dosage} \u2022 $status'),
              onTap: () => pushPage(
                context,
                MedicineDetailScreen(medicineId: dose.medicineId),
              ),
            ),
            Padding(padding: const EdgeInsets.only(left: 8), child: action),
          ],
        ),
      ),
    );
  }
}
