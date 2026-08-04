import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../class_management/presentation/providers/class_providers.dart';
import '../../../dashboard/domain/entities/chronic_latecomer.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart'
    show chronicLatecomersProvider, leaveTypeBreakdownProvider;
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
        const _ChronicLatecomersSection(),
        _LeaveTypeBreakdownSection(range: range),
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

/// Students with repeated "lewat" days in a rolling 7-day window, ending
/// today -- distinct from the At-Risk list above, which uses the selected
/// period's overall rate. This is a short-horizon behavioural flag, so it's
/// deliberately not tied to the period picker.
class _ChronicLatecomersSection extends ConsumerStatefulWidget {
  const _ChronicLatecomersSection();

  @override
  ConsumerState<_ChronicLatecomersSection> createState() => _ChronicLatecomersSectionState();
}

class _ChronicLatecomersSectionState extends ConsumerState<_ChronicLatecomersSection> {
  int _minLate = 3;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final referenceDate = DateTime(today.year, today.month, today.day);
    final latecomersAsync = ref.watch(
      chronicLatecomersProvider((referenceDate: referenceDate, windowDays: 7, minLate: _minLate)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Chronic Latecomers (Last 7 Days)', style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            Text(
              'Students with repeated "lewat" days in the trailing 7-day window.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Minimum late days:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2+')),
                    ButtonSegment(value: 3, label: Text('3+')),
                    ButtonSegment(value: 5, label: Text('5+')),
                  ],
                  selected: {_minLate},
                  onSelectionChanged: (selection) => setState(() => _minLate = selection.first),
                ),
              ],
            ),
            const SizedBox(height: 8),
            latecomersAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No students meet this threshold in the last 7 days.'),
                  );
                }
                return Column(
                  children: [
                    for (final s in students) _LatecomerRow(student: s),
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

class _LatecomerRow extends StatelessWidget {
  const _LatecomerRow({required this.student});

  final ChronicLatecomer student;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(student.fullName),
      subtitle: Text(student.className),
      trailing: Text(
        '${student.lateCount}x lewat',
        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// How the selected period's absence days split between unexplained
/// (tidak_hadir) and the two excused-leave types -- surfaces whether the
/// exception workflow (cuti_sakit / urusan_rasmi) is actually being used.
class _LeaveTypeBreakdownSection extends ConsumerWidget {
  const _LeaveTypeBreakdownSection({required this.range});

  final DateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(leaveTypeBreakdownProvider(range));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_busy, color: Colors.indigo.shade400),
                const SizedBox(width: 12),
                Expanded(child: Text('Leave-Type Breakdown', style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            Text(
              'How absence days split between unexplained and excused leave for the selected period.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            breakdownAsync.when(
              data: (b) {
                if (b.total == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No absence/leave days recorded for this period.'),
                  );
                }
                return Column(
                  children: [
                    _LeaveTypeBar(
                      label: 'Tidak Hadir (unexplained)',
                      count: b.tidakHadirCount,
                      total: b.total,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 8),
                    _LeaveTypeBar(
                      label: 'Cuti Sakit',
                      count: b.cutiSakitCount,
                      total: b.total,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(height: 8),
                    _LeaveTypeBar(
                      label: 'Urusan Rasmi',
                      count: b.urusanRasmiCount,
                      total: b.total,
                      color: Colors.teal.shade400,
                    ),
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

class _LeaveTypeBar extends StatelessWidget {
  const _LeaveTypeBar({required this.label, required this.count, required this.total, required this.color});

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total * 100;
    return Row(
      children: [
        SizedBox(width: 150, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
              ),
              FractionallySizedBox(
                widthFactor: (pct / 100).clamp(0, 1),
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 90, child: Text('$count (${pct.toStringAsFixed(0)}%)', textAlign: TextAlign.right)),
      ],
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
