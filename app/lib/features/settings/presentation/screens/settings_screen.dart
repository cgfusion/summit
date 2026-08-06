import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/app_shell.dart';
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
      appBar: AppBar(leading: const HomeBackButton(), title: const Text('Settings')),
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
        _MeritComponentsSection(),
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

class _MeritComponentsSection extends ConsumerStatefulWidget {
  const _MeritComponentsSection();

  @override
  ConsumerState<_MeritComponentsSection> createState() => _MeritComponentsSectionState();
}

class _MeritComponentsSectionState extends ConsumerState<_MeritComponentsSection> {
  bool? _enableHadir;
  bool? _enableTepatMasa;
  bool? _enableKembaliRehat;
  bool? _enableKekalSesi;
  bool? _enableBonus;
  int? _maxPoints;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).updateMeritSettings(
            enableHadir: _enableHadir!,
            enableTepatMasa: _enableTepatMasa!,
            enableKembaliRehat: _enableKembaliRehat!,
            enableKekalSesi: _enableKekalSesi!,
            enableBonus: _enableBonus!,
            maxPoints: _maxPoints!,
          );
      ref.invalidate(schoolSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merit components updated.')));
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
            _enableHadir ??= settings.meritEnableHadir;
            _enableTepatMasa ??= settings.meritEnableTepatMasa;
            _enableKembaliRehat ??= settings.meritEnableKembaliRehat;
            _enableKekalSesi ??= settings.meritEnableKekalSesi;
            _enableBonus ??= settings.meritEnableBonus;
            _maxPoints ??= settings.meritMaxPoints;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Merit Components', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'A disabled component no longer counts toward merit points at all.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hadir ke sekolah'),
                  value: _enableHadir!,
                  onChanged: (v) => setState(() => _enableHadir = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Masuk kelas tepat masa'),
                  value: _enableTepatMasa!,
                  onChanged: (v) => setState(() => _enableTepatMasa = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kembali selepas rehat'),
                  subtitle: const Text('Off by default -- hard to verify reliably in practice'),
                  value: _enableKembaliRehat!,
                  onChanged: (v) => setState(() => _enableKembaliRehat = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kekal hingga tamat sesi'),
                  value: _enableKekalSesi!,
                  onChanged: (v) => setState(() => _enableKekalSesi = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bonus points'),
                  subtitle: const Text('Off by default -- ad hoc, opt-in'),
                  value: _enableBonus!,
                  onChanged: (v) => setState(() => _enableBonus = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    initialValue: _maxPoints.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max points per day', border: OutlineInputBorder()),
                    onChanged: (v) => _maxPoints = int.tryParse(v) ?? _maxPoints,
                  ),
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
              'Enter the staff member\'s email and an invite link will be sent to them. They set their own password.',
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
    var loading = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Invite Staff'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
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
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: loading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      final name = nameController.text.trim();
                      if (email.isEmpty || name.isEmpty) {
                        setDialogState(() => errorText = 'Email and name are required.');
                        return;
                      }
                      setDialogState(() {
                        loading = true;
                        errorText = null;
                      });
                      try {
                        final message = await ref.read(settingsRepositoryProvider).inviteStaff(
                              email: email,
                              fullName: name,
                              role: role,
                            );
                        ref.invalidate(staffListProvider);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (error) {
                        setDialogState(() {
                          loading = false;
                          errorText = error.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              icon: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(loading ? 'Sending invite…' : 'Invite & Add'),
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
