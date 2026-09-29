import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/medicine_store.dart';
import '../utils.dart';

/// Screen 5 - Dose history with adherence summary and filter.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _filter = 0; // 0 all, 1 taken, 2 skipped

  @override
  Widget build(BuildContext context) {
    final store = MedicineStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.history();
        final logs = all.where((l) {
          if (_filter == 1) return l.status == DoseStatus.taken;
          if (_filter == 2) return l.status == DoseStatus.skipped;
          return true;
        }).toList();
        final cs = Theme.of(context).colorScheme;

        final rows = <Widget>[];
        DateTime? lastDay;
        for (final l in logs) {
          if (lastDay == null || !isSameDay(lastDay, l.scheduled)) {
            lastDay = l.scheduled;
            rows.add(Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(dayLabel(l.scheduled),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.primary)),
            ));
          }
          final taken = l.status == DoseStatus.taken;
          rows.add(ListTile(
            leading: Icon(
              taken ? Icons.check_circle : Icons.remove_circle_outline,
              color: taken ? Colors.green : cs.outline,
            ),
            title: Text(l.medicineName),
            subtitle: Text('${l.dosage} \u2022 ${TimeOfDay.fromDateTime(l.scheduled).format(context)}'),
            trailing: Text(taken ? 'Taken' : 'Skipped'),
          ));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('History')),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: cs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Text('${(store.adherence * 100).round()}%',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text('Adherence across ${all.length} logged doses'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All')),
                    ButtonSegment(value: 1, label: Text('Taken')),
                    ButtonSegment(value: 2, label: Text('Skipped')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No history yet')),
                )
              else
                ...rows,
            ],
          ),
        );
      },
    );
  }
}
