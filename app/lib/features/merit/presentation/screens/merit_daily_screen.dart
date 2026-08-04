import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../class_management/presentation/providers/class_providers.dart';
import '../../../settings/domain/entities/school_settings.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/merit_day.dart';
import '../providers/merit_providers.dart';

class MeritDailyScreen extends ConsumerWidget {
  const MeritDailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meritAsync = ref.watch(dailyMeritProvider);
    final classesAsync = ref.watch(classesProvider);
    final selectedDate = ref.watch(meritDateFilterProvider);
    final selectedClassId = ref.watch(meritClassFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const HomeBackButton(),
        title: const Text('Merit Harian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Rewards',
            onPressed: () => context.push('/merit/rewards'),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Class summary',
            onPressed: () => context.push('/merit/class-summary'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(DateFormat('d MMM yyyy').format(selectedDate)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      ref.read(meritDateFilterProvider.notifier).state = picked;
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: classesAsync.when(
                    data: (classes) => DropdownMenu<String?>(
                      label: const Text('Class'),
                      initialSelection: selectedClassId,
                      dropdownMenuEntries: [
                        const DropdownMenuEntry(value: null, label: 'All classes'),
                        ...classes.map((c) => DropdownMenuEntry(value: c.id, label: c.name)),
                      ],
                      onSelected: (value) => ref.read(meritClassFilterProvider.notifier).state = value,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: meritAsync.when(
              data: (days) {
                if (days.isEmpty) {
                  return const Center(child: Text('No merit records for this day yet.'));
                }
                return ListView.separated(
                  itemCount: days.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    return _MeritDayTile(day: day);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Failed to load merit records: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeritDayTile extends ConsumerWidget {
  const _MeritDayTile({required this.day});

  final MeritDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final present = day.attendanceStatus == AttendanceStatus.hadir || day.attendanceStatus == AttendanceStatus.lewat;
    final settings = ref.watch(schoolSettingsProvider).value;

    return ListTile(
      title: Text(day.studentName),
      subtitle: Row(
        children: [
          if (settings == null || settings.meritEnableHadir) _PointDot(label: 'H', earned: day.pointHadir == 1),
          if (settings == null || settings.meritEnableTepatMasa) _PointDot(label: 'T', earned: day.pointTepatMasa == 1),
          if (settings != null && settings.meritEnableKembaliRehat)
            _PointDot(label: 'R', earned: day.pointKembaliRehat == 1),
          if (settings == null || settings.meritEnableKekalSesi) _PointDot(label: 'S', earned: day.pointKekalSesi == 1),
          if (day.bonus > 0) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text('+${day.bonus}'),
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.amber.shade100,
            ),
          ],
        ],
      ),
      trailing: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text('${day.totalPoints}'),
      ),
      onTap: present ? () => _openEditSheet(context, ref, day) : null,
      enabled: present,
    );
  }

  Future<void> _openEditSheet(BuildContext context, WidgetRef ref, MeritDay day) {
    final settings = ref.read(schoolSettingsProvider).value;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MeritEditSheet(day: day, settings: settings),
    );
  }
}

class _PointDot extends StatelessWidget {
  const _PointDot({required this.label, required this.earned});

  final String label;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: earned ? Colors.green : Colors.grey.shade300,
        child: Text(label, style: TextStyle(fontSize: 11, color: earned ? Colors.white : Colors.black54)),
      ),
    );
  }
}

class _MeritEditSheet extends ConsumerStatefulWidget {
  const _MeritEditSheet({required this.day, required this.settings});

  final MeritDay day;
  final SchoolSettings? settings;

  @override
  ConsumerState<_MeritEditSheet> createState() => _MeritEditSheetState();
}

class _MeritEditSheetState extends ConsumerState<_MeritEditSheet> {
  late bool _onTimeToClass = widget.day.pointTepatMasa == 1;
  late bool _returnedAfterRecess = widget.day.pointKembaliRehat == 1;
  late bool _stayedUntilEnd = widget.day.pointKekalSesi == 1;
  final _bonusController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bonusController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = ref.read(meritRepositoryProvider);
    try {
      await repository.setException(
        studentId: widget.day.studentId,
        date: widget.day.schoolDate,
        lateToClass: !_onTimeToClass,
        missedRecessReturn: !_returnedAfterRecess,
        leftEarly: !_stayedUntilEnd,
      );

      final bonusPoints = int.tryParse(_bonusController.text.trim());
      if (bonusPoints != null && bonusPoints > 0) {
        await repository.addBonus(
          studentId: widget.day.studentId,
          date: widget.day.schoolDate,
          points: bonusPoints,
          reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        );
      }

      ref.invalidate(dailyMeritProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final showTepatMasa = settings == null || settings.meritEnableTepatMasa;
    final showKembaliRehat = settings != null && settings.meritEnableKembaliRehat;
    final showKekalSesi = settings == null || settings.meritEnableKekalSesi;
    final showBonus = settings != null && settings.meritEnableBonus;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.day.studentName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (showTepatMasa)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Masuk kelas tepat masa'),
              subtitle: const Text('On time to every subject period today'),
              value: _onTimeToClass,
              onChanged: (value) => setState(() => _onTimeToClass = value),
            ),
          if (showKembaliRehat)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kembali selepas rehat'),
              subtitle: const Text('Returned to class after recess'),
              value: _returnedAfterRecess,
              onChanged: (value) => setState(() => _returnedAfterRecess = value),
            ),
          if (showKekalSesi)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kekal hingga tamat sesi'),
              subtitle: const Text('Stayed until session ended'),
              value: _stayedUntilEnd,
              onChanged: (value) => setState(() => _stayedUntilEnd = value),
            ),
          if (showBonus) ...[
            const Divider(),
            Text('Add bonus (optional)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _bonusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Points', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
