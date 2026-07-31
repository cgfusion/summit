import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../merit/domain/value_objects/date_range.dart';
import '../../../merit/presentation/providers/merit_providers.dart' show programPeriodProvider;
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
            data: (weeks) => _KpiReportBody(weeks: weeks),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Failed to load report: $error')),
          ),
        ),
      ],
    );
  }
}

class _KpiReportBody extends StatelessWidget {
  const _KpiReportBody({required this.weeks});

  final List<KpiTrendWeek> weeks;

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
