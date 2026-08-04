import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../dashboard/domain/entities/attendance_period_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/value_objects/date_range.dart';
import '../providers/merit_providers.dart';
import 'period_picker.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class MeritClassSummaryScreen extends ConsumerStatefulWidget {
  const MeritClassSummaryScreen({super.key});

  @override
  ConsumerState<MeritClassSummaryScreen> createState() => _MeritClassSummaryScreenState();
}

class _MeritClassSummaryScreenState extends ConsumerState<MeritClassSummaryScreen> {
  late DateRange _range = thisWeekRange();
  DateTime _attendanceReferenceDate = _dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(classPeriodSummaryProvider(_range));

    return Scaffold(
      appBar: AppBar(title: const Text('Class Merit Summary')),
      body: ListView(
        children: [
          PeriodPicker(range: _range, onChanged: (range) => setState(() => _range = range)),
          summaryAsync.when(
            data: (classes) {
              if (classes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No merit records for this period yet.')),
                );
              }
              final sorted = [...classes]..sort((a, b) => b.pct.compareTo(a.pct));
              return Column(
                children: [
                  for (var i = 0; i < sorted.length; i++) ...[
                    ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(sorted[i].className),
                      subtitle: Text(
                        '${sorted[i].totalPoints}/${sorted[i].maxPoints} pts · '
                        'Transisi terlepas: ${sorted[i].missedRecessReturnRate.toStringAsFixed(1)}%',
                      ),
                      trailing: Text('${sorted[i].pct.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (i < sorted.length - 1) const Divider(height: 1),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Failed to load class summary: $error')),
            ),
          ),
          const Divider(height: 32, thickness: 8),
          _AttendanceSummarySection(
            referenceDate: _attendanceReferenceDate,
            onDateChanged: (date) => setState(() => _attendanceReferenceDate = date),
          ),
        ],
      ),
    );
  }
}

/// Day/week/month/year attendance % per class + whole-school, per the
/// teacher's request: week/month/year use the FULL period's school-day
/// count as denominator (not days elapsed so far), so mid-period this reads
/// as running progress and only hits its final value once the period ends.
class _AttendanceSummarySection extends ConsumerWidget {
  const _AttendanceSummarySection({required this.referenceDate, required this.onDateChanged});

  final DateTime referenceDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attendancePeriodSummaryProvider(referenceDate));

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Week/month/year % counts against that full period\'s school days, so it reads as '
            'progress-so-far and reaches its final value once the period ends.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text('As of ${DateFormat('d MMM yyyy').format(referenceDate)}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: referenceDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) onDateChanged(_dateOnly(picked));
            },
          ),
          const SizedBox(height: 12),
          async.when(
            data: (rows) {
              if (rows.isEmpty) return const Text('No attendance data yet.');
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Class')),
                    DataColumn(label: Text('Day'), numeric: true),
                    DataColumn(label: Text('Week'), numeric: true),
                    DataColumn(label: Text('Month'), numeric: true),
                    DataColumn(label: Text('Year'), numeric: true),
                  ],
                  rows: [for (final row in rows) _buildRow(context, row)],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Failed to load: $error'),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(BuildContext context, AttendancePeriodSummary row) {
    final style = row.isWholeSchool
        ? const TextStyle(fontWeight: FontWeight.bold)
        : const TextStyle();
    return DataRow(
      color: row.isWholeSchool ? WidgetStatePropertyAll(Theme.of(context).colorScheme.primaryContainer) : null,
      cells: [
        DataCell(Text(row.className, style: style)),
        DataCell(Text('${row.dayRate}%', style: style)),
        DataCell(Text('${row.weekRate}%', style: style)),
        DataCell(Text('${row.monthRate}%', style: style)),
        DataCell(Text('${row.yearRate}%', style: style)),
      ],
    );
  }
}
