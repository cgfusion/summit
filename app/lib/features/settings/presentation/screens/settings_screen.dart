import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../merit/presentation/providers/merit_providers.dart' show programPeriodProvider;
import '../../domain/entities/cutoff_time_row.dart';
import '../../domain/entities/staff_profile.dart';
import '../providers/settings_providers.dart';

const _dayLabels = {1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday'};

const _roleOptions = [
  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
  DropdownMenuItem(value: 'staff', child: Text('Staff')),
  DropdownMenuItem(value: 'admin', child: Text('Admin')),
];

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String _formatTimeForDb(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m:00';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: profileAsync.when(
        data: (profile) {
          if (profile?.role != 'admin') {
            return const Center(child: Text('Only admins can access Settings.'));
          }
          return const _SettingsBody();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        _ProgramPeriodSection(),
        SizedBox(height: 16),
        _CutoffTimesSection(),
        SizedBox(height: 16),
        _StaffSection(),
      ],
    );
  }
}

class _ProgramPeriodSection extends ConsumerStatefulWidget {
  const _ProgramPeriodSection();

  @override
  ConsumerState<_ProgramPeriodSection> createState() => _ProgramPeriodSectionState();
}

class _ProgramPeriodSectionState extends ConsumerState<_ProgramPeriodSection> {
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

  Future<void> _save() async {
    if (_start == null || _end == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).updateProgramPeriod(start: _start!, end: _end!);
      ref.invalidate(schoolSettingsProvider);
      ref.invalidate(programPeriodProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program period updated.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(schoolSettingsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: settingsAsync.when(
          data: (settings) {
            _start ??= settings.programStartDate;
            _end ??= settings.programEndDate;
            final format = DateFormat('d MMM yyyy');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Program Period', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _start!,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _start = picked);
                        },
                        child: Text('Start: ${format.format(_start!)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _end!,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _end = picked);
                        },
                        child: Text('End: ${format.format(_end!)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text('Failed to load: $error'),
        ),
      ),
    );
  }
}

class _CutoffTimesSection extends ConsumerWidget {
  const _CutoffTimesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cutoffAsync = ref.watch(cutoffTimesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session Cutoff Times', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Last on-time arrival time. A scan after this is marked Lewat.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            cutoffAsync.when(
              data: (rows) {
                final bySession = <String, Map<int, CutoffTimeRow>>{};
                for (final row in rows) {
                  bySession.putIfAbsent(row.session, () => {})[row.dayOfWeek] = row;
                }
                return Column(
                  children: [
                    for (final session in ['pagi', 'petang'])
                      _SessionCutoffTable(session: session, rowsByDay: bySession[session] ?? {}),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Text('Failed to load: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCutoffTable extends StatelessWidget {
  const _SessionCutoffTable({required this.session, required this.rowsByDay});

  final String session;
  final Map<int, CutoffTimeRow> rowsByDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session == 'pagi' ? 'Pagi (Morning)' : 'Petang (Afternoon)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var day = 1; day <= 5; day++) _CutoffChip(session: session, dayOfWeek: day, row: rowsByDay[day]),
            ],
          ),
        ],
      ),
    );
  }
}

class _CutoffChip extends ConsumerWidget {
  const _CutoffChip({required this.session, required this.dayOfWeek, required this.row});

  final String session;
  final int dayOfWeek;
  final CutoffTimeRow? row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _dayLabels[dayOfWeek] ?? 'Day $dayOfWeek';
    final timeText = row == null ? '--:--' : row!.cutoffTime.substring(0, 5);
    return ActionChip(
      label: Text('$label: $timeText'),
      onPressed: row == null
          ? null
          : () async {
              final picked = await showTimePicker(context: context, initialTime: _parseTime(row!.cutoffTime));
              if (picked == null) return;
              await ref.read(settingsRepositoryProvider).updateCutoffTime(
                    session: session,
                    dayOfWeek: dayOfWeek,
                    cutoffTime: _formatTimeForDb(picked),
                  );
              ref.invalidate(cutoffTimesProvider);
            },
    );
  }
}

class _StaffSection extends ConsumerWidget {
  const _StaffSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Staff Accounts', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Staff'),
                  onPressed: () => _showAddStaffDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'The person must already have signed in at least once before they can be added here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            staffAsync.when(
              data: (staff) => Column(children: staff.map((s) => _StaffRow(staff: s)).toList()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Text('Failed to load: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddStaffDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    var role = 'teacher';
    String? errorText;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add Staff'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                items: _roleOptions,
                onChanged: (value) => setDialogState(() => role = value ?? 'teacher'),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(errorText!, style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(settingsRepositoryProvider).upsertStaffByEmail(
                        email: emailController.text.trim(),
                        fullName: nameController.text.trim(),
                        role: role,
                      );
                  ref.invalidate(staffListProvider);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (error) {
                  setDialogState(() => errorText = error.toString());
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffRow extends ConsumerWidget {
  const _StaffRow({required this.staff});

  final StaffProfile staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(staff.fullName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: staff.role,
            items: _roleOptions,
            onChanged: (role) async {
              if (role == null || role == staff.role) return;
              await ref.read(settingsRepositoryProvider).updateStaffRole(profileId: staff.id, role: role);
              ref.invalidate(staffListProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove access',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Remove staff access?'),
                  content: Text('${staff.fullName} will lose access to the app. Their login itself is not deleted.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(settingsRepositoryProvider).removeStaff(profileId: staff.id);
                ref.invalidate(staffListProvider);
              }
            },
          ),
        ],
      ),
    );
  }
}
