import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../class_management/presentation/providers/class_providers.dart';
import '../../../merit/domain/entities/student_period_summary.dart';
import '../../../merit/domain/value_objects/date_range.dart';
import '../../../merit/presentation/providers/merit_providers.dart' show programPeriodProvider, studentPeriodSummaryProvider;
import '../../../merit/presentation/screens/period_picker.dart';
import '../../domain/entities/kpi_trend_week.dart';
import '../providers/reports_providers.dart';

/// KPI dashboard per KK D2C.docx section 18.0. Only the 3 indicators
/// derivable from current data are shown (attendance %, repeat absence,
/// late/missed-recess trend) -- the other 2 need the mentor/escalation
/// module, deferred when the merit module was built.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programPeriodAsync = ref.watch(programPeriodProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: programPeriodAsync.when(
        data: (period) => _ReportsBody(defaultRange: period),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load program period: $error')),
      ),
    );
  }
}

class _ReportsBody extends ConsumerStatefulWidget {
  const _ReportsBody({required this.defaultRange});

  final DateRange defaultRange;

  @override
  ConsumerState<_ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends ConsumerState<_ReportsBody> {
  late DateRange _range = widget.defaultRange;

  @override
  Widget build(BuildContext context) {
    final trendAsync = ref.watch(weeklyKpiTrendProvider(_range));
    final session = ref.watch(reportsSessionFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SegmentedButton<String?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Semua')),
              ButtonSegment(value: 'pagi', label: Text('Pagi')),
              ButtonSegment(value: 'petang', label: Text('Petang')),
            ],
            selected: {session},
            onSelectionChanged: (selection) => ref.read(reportsSessionFilterProvider.notifier).state = selection.first,
          ),
        ),
        PeriodPicker(range: _range, onChanged: (range) => setState(() => _range = range)),
        Expanded(
          child: trendAsync.when(
            data: (weeks) => _KpiReportBody(weeks: weeks, range: _range),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Failed to load report: $error')),
          ),
        ),
      ],
    );
  }
}

class _KpiReportBody extends StatelessWidget {
  const _KpiReportBody({required this.weeks, required this.range});

  final List<KpiTrendWeek> weeks;
  final DateRange range;

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) {
      return const Center(child: Text('No attendance records for this period yet.'));
    }
    final first = weeks.first;
    final last = weeks.last;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _AttendanceRateCard(first: first, last: last),
        _RepeatAbsenceCard(first: first, last: last),
        _AtRiskStudentsSection(range: range),
        _LateTransitionCard(first: first, last: last),
        const _UnavailableKpiNote(),
        const SizedBox(height: 16),
        Text('Weekly Breakdown', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...weeks.map((week) => _WeekRow(week: week)),
      ],
    );
  }
}

/// Students whose attendance rate for the selected period falls below a
/// threshold -- the actual "who" behind the Repeat Absence KPI's raw count
/// above, so a principal has an actionable intervention list instead of
/// just a number. Excused absences (cuti_sakit/urusan_rasmi) don't count
/// against the rate, only unexcused (tidak_hadir) vs present (hadir/lewat).
class _AtRiskStudentsSection extends ConsumerStatefulWidget {
  const _AtRiskStudentsSection({required this.range});

  final DateRange range;

  @override
  ConsumerState<_AtRiskStudentsSection> createState() => _AtRiskStudentsSectionState();
}

class _AtRiskStudentsSectionState extends ConsumerState<_AtRiskStudentsSection> {
  double _threshold = 80;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(studentPeriodSummaryProvider(widget.range));
    final classesAsync = ref.watch(classesProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('At-Risk Students', style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            Text(
              'Attendance rate below threshold for the selected period. Excused leave doesn\'t count against the rate.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Threshold:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 90, label: Text('90%')),
                    ButtonSegment(value: 80, label: Text('80%')),
                    ButtonSegment(value: 70, label: Text('70%')),
                  ],
                  selected: {_threshold},
                  onSelectionChanged: (selection) => setState(() => _threshold = selection.first),
                ),
              ],
            ),
            const SizedBox(height: 8),
            summaryAsync.when(
              data: (students) {
                final classNames = {
                  for (final c in classesAsync.value ?? []) c.id: c.name,
                };
                final atRisk = students.where((s) => s.daysPresent + s.daysAbsent > 0).where((s) {
                  final rate = s.daysPresent / (s.daysPresent + s.daysAbsent) * 100;
                  return rate < _threshold;
                }).toList()
                  ..sort(
                    (a, b) => (a.daysPresent / (a.daysPresent + a.daysAbsent))
                        .compareTo(b.daysPresent / (b.daysPresent + b.daysAbsent)),
                  );
                if (atRisk.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No students below threshold for this period.'),
                  );
                }
                return Column(
                  children: [
                    for (final s in atRisk) _AtRiskRow(student: s, className: classNames[s.classId]),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Text('Failed to load: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtRiskRow extends StatelessWidget {
  const _AtRiskRow({required this.student, required this.className});

  final StudentPeriodSummary student;
  final String? className;

  @override
  Widget build(BuildContext context) {
    final total = student.daysPresent + student.daysAbsent;
    final rate = total == 0 ? 0.0 : student.daysPresent / total * 100;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(student.fullName),
      subtitle: Text(className ?? '-'),
      trailing: Text(
        '${rate.toStringAsFixed(1)}%  (${student.daysPresent}/$total)',
        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.subtitle, required this.metTarget, required this.child});

  final String title;
  final String subtitle;
  final bool metTarget;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(metTarget ? Icons.check_circle : Icons.info_outline, color: metTarget ? Colors.green : Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceRateCard extends StatelessWidget {
  const _AttendanceRateCard({required this.first, required this.last});

  final KpiTrendWeek first;
  final KpiTrendWeek last;

  @override
  Widget build(BuildContext context) {
    final delta = last.attendanceRate - first.attendanceRate;
    return _KpiCard(
      title: 'Peratus Kehadiran',
      subtitle: 'Target: naik sekurang-kurangnya 5 mata peratus',
      metTarget: delta >= 5.0,
      child: Text(
        '${first.attendanceRate.toStringAsFixed(1)}% → ${last.attendanceRate.toStringAsFixed(1)}% '
        '(${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} mp)',
      ),
    );
  }
}

class _RepeatAbsenceCard extends StatelessWidget {
  const _RepeatAbsenceCard({required this.first, required this.last});

  final KpiTrendWeek first;
  final KpiTrendWeek last;

  @override
  Widget build(BuildContext context) {
    if (first.repeatAbsentStudents == 0) {
      return _KpiCard(
        title: 'Ketidakhadiran Berulang',
        subtitle: 'Target: kurangkan sekurang-kurangnya 20%',
        metTarget: last.repeatAbsentStudents == 0,
        child: Text('${first.repeatAbsentStudents} → ${last.repeatAbsentStudents} murid (tiada kes asas untuk dibandingkan)'),
      );
    }
    final reductionPct = (first.repeatAbsentStudents - last.repeatAbsentStudents) / first.repeatAbsentStudents * 100;
    return _KpiCard(
      title: 'Ketidakhadiran Berulang',
      subtitle: 'Target: kurangkan sekurang-kurangnya 20%',
      metTarget: reductionPct >= 20.0,
      child: Text(
        '${first.repeatAbsentStudents} → ${last.repeatAbsentStudents} murid '
        '(${reductionPct >= 0 ? '-' : '+'}${reductionPct.abs().toStringAsFixed(1)}%)',
      ),
    );
  }
}

class _LateTransitionCard extends StatelessWidget {
  const _LateTransitionCard({required this.first, required this.last});

  final KpiTrendWeek first;
  final KpiTrendWeek last;

  @override
  Widget build(BuildContext context) {
    final lateDelta = last.lateCount - first.lateCount;
    final recessDelta = last.missedRecessCount - first.missedRecessCount;
    return _KpiCard(
      title: 'Lewat & Tidak Kembali Selepas Rehat',
      subtitle: 'Target: trend menurun sepanjang program',
      metTarget: lateDelta <= 0 && recessDelta <= 0,
      child: Text(
        'Lewat: ${first.lateCount} → ${last.lateCount}   '
        'Tidak kembali rehat: ${first.missedRecessCount} → ${last.missedRecessCount}',
      ),
    );
  }
}

class _UnavailableKpiNote extends StatelessWidget {
  const _UnavailableKpiNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: const Text(
        "2 more indicators from the D2C plan (mentor coverage for at-risk students, and follow-up action "
        "timeliness) need the mentor/PRS assignment and case-tracking module, which hasn't been built yet.",
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.week});

  final KpiTrendWeek week;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('d MMM');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(format.format(week.weekStart))),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 18,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                ),
                FractionallySizedBox(
                  widthFactor: (week.attendanceRate / 100).clamp(0, 1),
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 46, child: Text('${week.attendanceRate.toStringAsFixed(0)}%', textAlign: TextAlign.right)),
          const SizedBox(width: 12),
          SizedBox(width: 90, child: Text('Lewat: ${week.lateCount}', style: Theme.of(context).textTheme.bodySmall)),
          SizedBox(width: 80, child: Text('Ulang: ${week.repeatAbsentStudents}', style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
