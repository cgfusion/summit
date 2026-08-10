import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../student/presentation/providers/student_providers.dart';
import '../../../student/presentation/screens/student_detail_sheet.dart';

void showDashboardAttendanceDrillDown(
  BuildContext context, {
  required DateTime date,
  required String title,
  String? initialStatusFilter,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _DashboardAttendanceSheet(
      date: date,
      title: title,
      initialStatusFilter: initialStatusFilter,
    ),
  );
}

class _DashboardStudentAttendanceItem {
  const _DashboardStudentAttendanceItem({
    required this.studentId,
    required this.fullName,
    required this.classId,
    required this.className,
    required this.statusToday,
    required this.attendanceRate,
  });

  final String studentId;
  final String fullName;
  final String classId;
  final String className;
  final String statusToday;
  final double attendanceRate;
}

final _dashboardAttendanceDrillDownProvider = FutureProvider.autoDispose
    .family<List<_DashboardStudentAttendanceItem>, DateTime>((ref, date) async {
  final client = ref.watch(supabaseClientProvider);
  final dateStr = formatDateOnly(date);

  // 1. Fetch today's attendance records
  final attRows = await client
      .from('attendance_days')
      .select('student_id, status, students!inner(id, full_name, class_id, enrollment_status, classes!inner(name))')
      .eq('school_date', dateStr)
      .eq('students.enrollment_status', 'active');

  // 2. Fetch overall period summary for attendance rates
  final summaryRows = await client.rpc('fn_student_period_summary', params: {
    'p_from': formatDateOnly(date.subtract(const Duration(days: 30))),
    'p_to': dateStr,
    'p_class_id': null,
  });

  final rateMap = <String, double>{};
  for (final s in (summaryRows as List)) {
    final sId = s['student_id'] as String;
    final present = (s['days_present'] as num).toDouble();
    final absent = (s['days_absent'] as num).toDouble();
    final total = present + absent;
    rateMap[sId] = total == 0 ? 100.0 : (present / total * 100);
  }

  final items = <_DashboardStudentAttendanceItem>[];
  for (final row in (attRows as List)) {
    final student = row['students'] as Map<String, dynamic>;
    final cls = student['classes'] as Map<String, dynamic>;
    final sId = student['id'] as String;

    items.add(_DashboardStudentAttendanceItem(
      studentId: sId,
      fullName: student['full_name'] as String,
      classId: student['class_id'] as String,
      className: cls['name'] as String,
      statusToday: row['status'] as String,
      attendanceRate: rateMap[sId] ?? 100.0,
    ));
  }

  items.sort((a, b) => a.fullName.compareTo(b.fullName));
  return items;
});

class _DashboardAttendanceSheet extends ConsumerStatefulWidget {
  const _DashboardAttendanceSheet({
    required this.date,
    required this.title,
    this.initialStatusFilter,
  });

  final DateTime date;
  final String title;
  final String? initialStatusFilter;

  @override
  ConsumerState<_DashboardAttendanceSheet> createState() => _DashboardAttendanceSheetState();
}

class _DashboardAttendanceSheetState extends ConsumerState<_DashboardAttendanceSheet> {
  late String? _statusFilter = widget.initialStatusFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(_dashboardAttendanceDrillDownProvider(widget.date));
    final dateStr = DateFormat('d MMMM yyyy').format(widget.date);

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
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.people_alt, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
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
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cari nama murid atau kelas...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String?>(
                      segments: const [
                        ButtonSegment(value: null, label: Text('Semua')),
                        ButtonSegment(value: 'hadir', label: Text('Hadir')),
                        ButtonSegment(value: 'lewat', label: Text('Lewat')),
                        ButtonSegment(value: 'tidak_hadir', label: Text('Tidak Hadir')),
                        ButtonSegment(value: 'cuti_sakit', label: Text('Cuti Sakit')),
                        ButtonSegment(value: 'urusan_rasmi', label: Text('Urusan Rasmi')),
                      ],
                      selected: {_statusFilter},
                      onSelectionChanged: (sel) => setState(() => _statusFilter = sel.first),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: listAsync.when(
                data: (items) {
                  final filtered = items.where((item) {
                    if (_statusFilter == 'hadir') {
                      if (item.statusToday == 'tidak_hadir') return false;
                    } else if (_statusFilter != null && item.statusToday != _statusFilter) {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty) {
                      return item.fullName.toLowerCase().contains(_searchQuery) ||
                          item.className.toLowerCase().contains(_searchQuery);
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Tiada rekod murid mengikut kriteria carian ini.'),
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
                      final isAbsent = item.statusToday == 'tidak_hadir';
                      final isLate = item.statusToday == 'lewat';

                      final badgeColor = isAbsent
                          ? Colors.red
                          : isLate
                              ? Colors.amber.shade900
                              : Colors.green;

                      final statusLabel = item.statusToday == 'hadir'
                          ? 'Hadir'
                          : item.statusToday == 'lewat'
                              ? 'Lewat'
                              : item.statusToday == 'tidak_hadir'
                                  ? 'Tidak Hadir'
                                  : item.statusToday == 'cuti_sakit'
                                      ? 'Cuti Sakit'
                                      : 'Urusan Rasmi';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        title: Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Kelas: ${item.className} • Kehadiran bulanan: ${item.attendanceRate.toStringAsFixed(1)}%'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          ],
                        ),
                        onTap: () async {
                          final fullStudent = await ref.read(studentRepositoryProvider).getById(item.studentId);
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
