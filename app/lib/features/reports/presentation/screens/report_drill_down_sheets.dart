import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../merit/domain/value_objects/date_range.dart';
import '../../../student/presentation/providers/student_providers.dart';
import '../../../student/presentation/screens/student_detail_sheet.dart';
import '../providers/reports_providers.dart';

/// Opens the Repeat Absence Drill-Down sheet showing all students with >= 2
/// unexcused absences in the selected period.
void showRepeatAbsenceDrillDown(BuildContext context, DateRange range) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RepeatAbsenceSheet(range: range),
  );
}

/// Opens the Class Attendance Rate Drill-Down sheet showing breakdown by class.
void showAttendanceRateDrillDown(BuildContext context, DateRange range) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ClassAttendanceRateSheet(range: range),
  );
}

/// Opens the Late & Missed Recess Drill-Down sheet.
void showLateTransitionDrillDown(BuildContext context, DateRange range) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _LateTransitionSheet(range: range),
  );
}

/// Opens the Leave-Type Breakdown Drill-Down sheet.
void showLeaveTypeDrillDown(BuildContext context, DateRange range, {String? initialStatus}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _LeaveTypeSheet(range: range, initialStatus: initialStatus),
  );
}

// -----------------------------------------------------------------------------
// 1. Repeat Absence Sheet
// -----------------------------------------------------------------------------
class _RepeatAbsenceSheet extends ConsumerStatefulWidget {
  const _RepeatAbsenceSheet({required this.range});

  final DateRange range;

  @override
  ConsumerState<_RepeatAbsenceSheet> createState() => _RepeatAbsenceSheetState();
}

class _RepeatAbsenceSheetState extends ConsumerState<_RepeatAbsenceSheet> {
  String _search = '';
  int _minAbsent = 2;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(repeatAbsentStudentsProvider((range: widget.range, minAbsent: _minAbsent)));
    final dateFormat = DateFormat('d MMM yyyy');
    final dateSubtitle = '${dateFormat.format(widget.range.from)} - ${dateFormat.format(widget.range.to)}';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_off, color: Colors.red.shade800),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Senarai Ketidakhadiran Berulang',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(dateSubtitle, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Cari nama murid atau kelas...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 2, label: Text('2+')),
                          ButtonSegment(value: 3, label: Text('3+')),
                          ButtonSegment(value: 5, label: Text('5+')),
                        ],
                        selected: {_minAbsent},
                        onSelectionChanged: (sel) => setState(() => _minAbsent = sel.first),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: listAsync.when(
                data: (students) {
                  final filtered = students.where((s) {
                    if (_search.isEmpty) return true;
                    return s.fullName.toLowerCase().contains(_search) ||
                        s.className.toLowerCase().contains(_search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Tiada murid memenuhi kriteria carian.'),
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: Text(
                            '${item.absentCount}',
                            style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Kelas: ${item.className} • ${item.session.toUpperCase()}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                '${item.absentCount} hari tidak hadir',
                                style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.attendanceRate.toStringAsFixed(1)}% hadir',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () async {
                          final fullStudent =
                              await ref.read(studentRepositoryProvider).getById(item.studentId);
                          if (fullStudent != null && context.mounted) {
                            showStudentDetailSheet(context, fullStudent);
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Gagal memuatkan data: $err')),
              ),
            ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 2. Class Attendance Rate Sheet
// -----------------------------------------------------------------------------
class _ClassAttendanceRateSheet extends ConsumerWidget {
  const _ClassAttendanceRateSheet({required this.range});

  final DateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(classAttendanceRatesProvider(range));
    final dateFormat = DateFormat('d MMM yyyy');
    final dateSubtitle = '${dateFormat.format(range.from)} - ${dateFormat.format(range.to)}';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bar_chart, color: Colors.blue.shade800),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peratus Kehadiran Mengikut Kelas',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(dateSubtitle, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: listAsync.when(
                data: (classes) {
                  if (classes.isEmpty) {
                    return const Center(child: Text('Tiada rekod kelas untuk tempoh ini.'));
                  }

                  return ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: classes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = classes[index];
                      final isGood = item.attendanceRate >= 90;
                      final isOk = item.attendanceRate >= 80;

                      final color = isGood
                          ? Colors.green
                          : isOk
                              ? Colors.orange
                              : Colors.red;

                      return Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.className,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '${item.attendanceRate.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: color.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.homeroomTeacherName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Guru Kelas: ${item.homeroomTeacherName}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: (item.attendanceRate / 100).clamp(0.0, 1.0),
                                    child: Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Hadir: ${item.presentCount} / Total: ${item.totalRecords}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Tidak Hadir: ${item.absentCount}',
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Gagal memuatkan data: $err')),
              ),
            ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Late & Missed Recess Sheet
// -----------------------------------------------------------------------------
class _LateTransitionSheet extends ConsumerStatefulWidget {
  const _LateTransitionSheet({required this.range});

  final DateRange range;

  @override
  ConsumerState<_LateTransitionSheet> createState() => _LateTransitionSheetState();
}

class _LateTransitionSheetState extends ConsumerState<_LateTransitionSheet> {
  String _filter = 'all'; // 'all', 'late', 'recess'

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(lateAndRecessRecordsProvider(widget.range));
    final dateFormat = DateFormat('d MMM yyyy');
    final dateSubtitle = '${dateFormat.format(widget.range.from)} - ${dateFormat.format(widget.range.to)}';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.access_time, color: Colors.amber.shade900),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lewat & Tidak Kembali Rehat',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(dateSubtitle, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('Semua')),
                      ButtonSegment(value: 'late', label: Text('Lewat')),
                      ButtonSegment(value: 'recess', label: Text('Tidak Kembali Rehat')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (sel) => setState(() => _filter = sel.first),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: listAsync.when(
                data: (students) {
                  final filtered = students.where((s) {
                    if (_filter == 'late' && s.lateCount == 0) return false;
                    if (_filter == 'recess' && s.missedRecessCount == 0) return false;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Tiada rekod untuk kriteria ini.'));
                  }

                  return ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        title: Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Kelas: ${item.className}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.lateCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Text(
                                  '${item.lateCount}x Lewat',
                                  style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (item.missedRecessCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.deepOrange.shade200),
                                ),
                                child: Text(
                                  '${item.missedRecessCount}x Rehat',
                                  style: TextStyle(color: Colors.deepOrange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        onTap: () async {
                          final fullStudent =
                              await ref.read(studentRepositoryProvider).getById(item.studentId);
                          if (fullStudent != null && context.mounted) {
                            showStudentDetailSheet(context, fullStudent);
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Gagal memuatkan data: $err')),
              ),
            ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 4. Leave-Type Sheet
// -----------------------------------------------------------------------------
class _LeaveTypeSheet extends ConsumerStatefulWidget {
  const _LeaveTypeSheet({required this.range, this.initialStatus});

  final DateRange range;
  final String? initialStatus;

  @override
  ConsumerState<_LeaveTypeSheet> createState() => _LeaveTypeSheetState();
}

class _LeaveTypeSheetState extends ConsumerState<_LeaveTypeSheet> {
  late String? _selectedStatus = widget.initialStatus;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(leaveRecordsProvider((range: widget.range, status: _selectedStatus)));
    final dateFormat = DateFormat('d MMM yyyy');
    final dateSubtitle = '${dateFormat.format(widget.range.from)} - ${dateFormat.format(widget.range.to)}';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.event_busy, color: Colors.indigo.shade800),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rekod Ketidakhadiran & Cuti',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(dateSubtitle, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('Semua')),
                      ButtonSegment(value: 'tidak_hadir', label: Text('Tidak Hadir')),
                      ButtonSegment(value: 'cuti_sakit', label: Text('Cuti Sakit')),
                      ButtonSegment(value: 'urusan_rasmi', label: Text('Urusan Rasmi')),
                    ],
                    selected: {_selectedStatus},
                    onSelectionChanged: (sel) => setState(() => _selectedStatus = sel.first),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: listAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(child: Text('Tiada rekod untuk tempoh ini.'));
                  }

                  return ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = records[index];
                      Color badgeColor;
                      String statusText;

                      if (item.status == 'cuti_sakit') {
                        badgeColor = Colors.blue;
                        statusText = 'Cuti Sakit';
                      } else if (item.status == 'urusan_rasmi') {
                        badgeColor = Colors.teal;
                        statusText = 'Urusan Rasmi';
                      } else {
                        badgeColor = Colors.red;
                        statusText = 'Tidak Hadir';
                      }

                      return ListTile(
                        title: Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Kelas: ${item.className} • ${dateFormat.format(item.schoolDate)}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        onTap: () async {
                          final fullStudent =
                              await ref.read(studentRepositoryProvider).getById(item.studentId);
                          if (fullStudent != null && context.mounted) {
                            showStudentDetailSheet(context, fullStudent);
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Gagal memuatkan data: $err')),
              ),
            ),
          ],
        );
      },
    );
  }
}
