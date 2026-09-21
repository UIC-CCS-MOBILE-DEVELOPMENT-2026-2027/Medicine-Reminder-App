import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/medicine_card.dart';
import 'add_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _notifications = NotificationService();
  List<Medicine> _medicines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final list = await _storage.loadMedicines();
    setState(() {
      _medicines = list;
      _loading = false;
    });
  }

  Future<void> _persistAndReschedule() async {
    await _storage.saveMedicines(_medicines);
  }

  Future<void> _openAddEdit({Medicine? existing}) async {
    final result = await Navigator.of(context).push<Medicine>(
      MaterialPageRoute(
        builder: (_) => AddEditScreen(medicine: existing),
      ),
    );

    if (result == null) return;

    setState(() {
      if (existing != null) {
        final index = _medicines.indexWhere((m) => m.id == existing.id);
        _medicines[index] = result;
      } else {
        _medicines.add(result);
      }
    });

    await _persistAndReschedule();
    await _notifications.scheduleForMedicine(result);
  }

  Future<void> _toggleActive(Medicine medicine, bool value) async {
    setState(() => medicine.isActive = value);
    await _persistAndReschedule();
    await _notifications.scheduleForMedicine(medicine);
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text('Remove ${medicine.name} and its reminders?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _notifications.cancelForMedicine(medicine);
    setState(() => _medicines.removeWhere((m) => m.id == medicine.id));
    await _persistAndReschedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _medicines.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = _medicines[index];
                    return MedicineCard(
                      medicine: medicine,
                      onTap: () => _openAddEdit(existing: medicine),
                      onToggleActive: (v) => _toggleActive(medicine, v),
                      onDelete: () => _deleteMedicine(medicine),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No medicines added yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Medicine" to set up your first reminder.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
