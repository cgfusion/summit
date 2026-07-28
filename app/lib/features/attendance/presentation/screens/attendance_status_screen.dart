import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../class_management/presentation/providers/class_providers.dart';
import '../../domain/entities/attendance_status.dart';
import '../providers/attendance_providers.dart';

class AttendanceStatusScreen extends ConsumerWidget {
  const AttendanceStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceForDateProvider);
    final classesAsync = ref.watch(classesProvider);
    final selectedDate = ref.watch(attendanceDateFilterProvider);
    final selectedClassId = ref.watch(attendanceClassFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan attendance QR',
            onPressed: () => context.push('/attendance/scan'),
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
                      ref.read(attendanceDateFilterProvider.notifier).state = picked;
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
                      onSelected: (value) => ref.read(attendanceClassFilterProvider.notifier).state = value,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: attendanceAsync.when(
              data: (days) {
                if (days.isEmpty) {
                  return const Center(child: Text('No attendance records for this day yet.'));
                }
                return ListView.separated(
                  itemCount: days.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    return ListTile(
                      title: Text(day.studentName ?? day.studentId),
                      subtitle: day.firstScanAt == null ? null : Text(DateFormat.Hm().format(day.firstScanAt!.toLocal())),
                      trailing: _StatusChip(status: day.status),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Failed to load attendance: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AttendanceStatus.hadir => Colors.green,
      AttendanceStatus.lewat => Colors.orange,
      AttendanceStatus.tidakHadir => Colors.red,
      AttendanceStatus.cutiSakit => Colors.blue,
      AttendanceStatus.urusanRasmi => Colors.purple,
    };
    return Chip(
      label: Text(status.label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}
