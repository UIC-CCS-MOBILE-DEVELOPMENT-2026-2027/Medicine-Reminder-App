import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/medicine_store.dart';
import '../utils.dart';

/// Screen 4 - Add / edit a medicine (pass [medicine] to edit).
class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key, this.medicine});
  final Medicine? medicine;

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  static const _forms = ['Tablet', 'Capsule', 'Liquid', 'Injection', 'Drops', 'Other'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dosage;
  late final TextEditingController _notes;
  late String _form;
  late List<TimeOfDay> _times;
  bool _timesError = false;

  bool get _editing => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    _name = TextEditingController(text: m?.name ?? '');
    _dosage = TextEditingController(text: m?.dosage ?? '');
    _notes = TextEditingController(text: m?.notes ?? '');
    _form = m?.form ?? 'Tablet';
    _times = m == null ? [const TimeOfDay(hour: 8, minute: 0)] : List.of(m.times);
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null || _times.contains(picked)) return;
    setState(() {
      _times.add(picked);
      _times.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      _timesError = false;
    });
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_times.isEmpty) setState(() => _timesError = true);
    if (!valid || _times.isEmpty) return;

    final store = MedicineStore.instance;
    final messenger = ScaffoldMessenger.of(context);
    final existing = widget.medicine;

    final saved = existing != null
        ? await runStoreAction(context, () async {
            existing
              ..name = _name.text.trim()
              ..dosage = _dosage.text.trim()
              ..form = _form
              ..notes = _notes.text.trim()
              ..times = List.of(_times);
            await store.updateMedicine(existing);
          })
        : await runStoreAction(
            context,
            () => store.addMedicine(Medicine(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: _name.text.trim(),
              dosage: _dosage.text.trim(),
              form: _form,
              notes: _notes.text.trim(),
              times: List.of(_times),
            )),
          );
    if (!saved || !mounted) return;

    if (existing != null) {
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Medicine updated')));
    } else {
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Medicine added')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit medicine' : 'Add medicine')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Medicine name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosage,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g. 500 mg)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a dosage' : null,
            ),
            const SizedBox(height: 20),
            Text('Form', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final f in _forms)
                  ChoiceChip(
                    label: Text(f),
                    selected: _form == f,
                    onSelected: (_) => setState(() => _form = f),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Reminder times', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final t in _times)
                  InputChip(
                    label: Text(t.format(context)),
                    onDeleted: () => setState(() => _times.remove(t)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add_alarm, size: 18),
                  label: const Text('Add time'),
                  onPressed: _addTime,
                ),
              ],
            ),
            if (_timesError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Add at least one reminder time',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_editing ? 'Save changes' : 'Save medicine'),
            ),
          ],
        ),
      ),
    );
  }
}
