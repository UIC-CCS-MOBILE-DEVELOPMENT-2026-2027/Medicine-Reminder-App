import 'package:flutter/material.dart';
import '../services/medicine_store.dart';

/// Screen 6 - Settings / profile.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  final _store = MedicineStore.instance;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _store.userName == 'Friend' ? '' : _store.userName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('All taken/skipped records will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) _store.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _store.updateSettings(name: v),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Enable reminders'),
                subtitle: const Text('Turn all medicine notifications on or off'),
                value: _store.remindersEnabled,
                onChanged: (v) => _store.updateSettings(reminders: v),
              ),
              const SizedBox(height: 8),
              Text('Snooze length', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 5, label: Text('5 min')),
                  ButtonSegment(value: 10, label: Text('10 min')),
                  ButtonSegment(value: 15, label: Text('15 min')),
                ],
                selected: {_store.snoozeMinutes},
                onSelectionChanged: (s) => _store.updateSettings(snooze: s.first),
              ),
              const Divider(height: 40),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Clear history'),
                onTap: _clearHistory,
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Medicine Reminder'),
                subtitle: Text('Version 1.0.0'),
              ),
            ],
          ),
        );
      },
    );
  }
}
