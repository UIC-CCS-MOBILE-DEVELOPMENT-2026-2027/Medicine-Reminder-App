import 'package:flutter/material.dart';
import '../services/medicine_store.dart';
import '../utils.dart';
import 'add_medicine_screen.dart';
import 'medicine_detail_screen.dart';

/// Screen 2 - Medicine list with search and Active/Paused filter.
class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  String _query = '';
  int _filter = 0; // 0 all, 1 active, 2 paused

  @override
  Widget build(BuildContext context) {
    final store = MedicineStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.medicines.where((m) {
          final matchesQuery = m.name.toLowerCase().contains(_query.toLowerCase());
          final matchesFilter = _filter == 0 || (_filter == 1 && m.active) || (_filter == 2 && !m.active);
          return matchesQuery && matchesFilter;
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('My Medicines')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search medicines',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All')),
                    ButtonSegment(value: 1, label: Text('Active')),
                    ButtonSegment(value: 2, label: Text('Paused')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No medicines found'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final m = items[i];
                          return ListTile(
                            leading: CircleAvatar(child: Icon(m.icon)),
                            title: Text(m.name),
                            subtitle: Text(
                              '${m.dosage} \u2022 ${m.times.length}x daily${m.active ? '' : ' \u2022 Paused'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => pushPage(context, MedicineDetailScreen(medicineId: m.id)),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Add medicine',
            onPressed: () => pushPage(context, const AddMedicineScreen()),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
