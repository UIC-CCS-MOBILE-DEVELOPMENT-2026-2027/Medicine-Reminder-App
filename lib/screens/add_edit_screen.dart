import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';

/// Form for adding a new medicine or editing an existing one.
/// Pass an existing [medicine] to edit it, or leave it null to add new.
class AddEditScreen extends StatefulWidget {
  final Medicine? medicine;

  const AddEditScreen({super.key, this.medicine});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;
  List<TimeOfDay> _times = [];

  bool get _isEditing => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _dosageController =
        TextEditingController(text: widget.medicine?.dosage ?? '');
    _notesController =
        TextEditingController(text: widget.medicine?.notes ?? '');
    _times = widget.medicine != null
        ? List.of(widget.medicine!.reminderTimes)
        : [const TimeOfDay(hour: 8, minute: 0)];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) {
      setState(() => _times[index] = picked);
    }
  }

  void _addTimeSlot() {
    setState(() => _times.add(const TimeOfDay(hour: 12, minute: 0)));
  }

  void _removeTimeSlot(int index) {
    if (_times.length == 1) return; // keep at least one reminder time
    setState(() => _times.removeAt(index));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final result = Medicine(
      id: widget.medicine?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      notes: _notesController.text.trim(),
      reminderTimes: _times,
      isActive: widget.medicine?.isActive ?? true,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medicine' : 'Add Medicine'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g. 500mg, 1 tablet)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a dosage' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reminder times',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _addTimeSlot,
                  icon: const Icon(Icons.add),
                  label: const Text('Add time'),
                ),
              ],
            ),
            ..._times.asMap().entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(time.format(context)),
                  onTap: () => _pickTime(index),
                  trailing: _times.length > 1
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeTimeSlot(index),
                        )
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
