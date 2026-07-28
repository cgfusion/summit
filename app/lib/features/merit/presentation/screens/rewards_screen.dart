import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/class_period_summary.dart';
import '../../domain/entities/merit_award.dart';
import '../../domain/entities/student_period_summary.dart';
import '../../domain/value_objects/date_range.dart';
import '../providers/merit_providers.dart';
import 'period_picker.dart';

class _Candidate {
  const _Candidate({required this.name, required this.metric, this.studentId, this.classId});

  final String name;
  final String metric;
  final String? studentId;
  final String? classId;
}

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thisWeek = thisWeekRange();
    final lastWeek = lastWeekRange();
    final thisMonth = thisMonthRange();
    final programPeriodAsync = ref.watch(programPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards & Recognition')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _StudentRewardSection(
            title: 'Kehadiran Penuh Mingguan',
            subtitle: 'Full weekly attendance',
            category: MeritAwardCategory.fullWeeklyAttendance,
            range: thisWeek,
            buildCandidates: (summaries) => summaries
                .where((s) => s.fullAttendance)
                .map((s) => _Candidate(name: s.fullName, metric: '${s.totalPoints}/${s.maxPoints} pts', studentId: s.studentId))
                .toList(),
          ),
          _StudentRewardSection(
            title: 'Kehadiran Penuh Bulanan',
            subtitle: 'Full monthly attendance',
            category: MeritAwardCategory.fullMonthlyAttendance,
            range: thisMonth,
            buildCandidates: (summaries) => summaries
                .where((s) => s.fullAttendance)
                .map((s) => _Candidate(name: s.fullName, metric: '${s.totalPoints}/${s.maxPoints} pts', studentId: s.studentId))
                .toList(),
          ),
          _ImprovementRewardSection(thisWeek: thisWeek, lastWeek: lastWeek),
          _ClassRewardSection(
            title: 'Kelas Paling Meningkat',
            subtitle: 'Most improved class (vs last week)',
            category: MeritAwardCategory.mostImprovedClass,
            range: thisWeek,
            compareRange: lastWeek,
            sortByImprovement: true,
          ),
          _ClassRewardSection(
            title: 'Transisi Terbaik',
            subtitle: 'Best transition (fewest missed recess returns)',
            category: MeritAwardCategory.bestTransition,
            range: thisWeek,
            metricBuilder: (c) => '${c.missedRecessReturnRate.toStringAsFixed(1)}% missed',
            sortAscendingBy: (c) => c.missedRecessReturnRate,
          ),
          programPeriodAsync.when(
            data: (period) => _ClassRewardSection(
              title: 'Kelas Merit Tertinggi',
              subtitle: 'Highest merit class (full program period)',
              category: MeritAwardCategory.highestMeritClass,
              range: period,
            ),
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (error, stackTrace) => Padding(padding: const EdgeInsets.all(16), child: Text('Failed to load program period: $error')),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

Future<void> _logAward(
  BuildContext context,
  WidgetRef ref, {
  required MeritAwardCategory category,
  required String scopeType,
  String? studentId,
  String? classId,
  required DateRange range,
}) async {
  final repository = ref.read(meritRepositoryProvider);
  await repository.logAward(
    category: category,
    scopeType: scopeType,
    studentId: studentId,
    classId: classId,
    periodStart: range.from,
    periodEnd: range.to,
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Award logged.')));
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate, required this.onAward});

  final _Candidate candidate;
  final VoidCallback onAward;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(candidate.name),
      subtitle: Text(candidate.metric),
      trailing: TextButton(onPressed: onAward, child: const Text('Log Award')),
    );
  }
}

class _StudentRewardSection extends ConsumerWidget {
  const _StudentRewardSection({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.range,
    required this.buildCandidates,
  });

  final String title;
  final String subtitle;
  final MeritAwardCategory category;
  final DateRange range;
  final List<_Candidate> Function(List<StudentPeriodSummary>) buildCandidates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(studentPeriodSummaryProvider(range));
    return _RewardCard(
      title: title,
      subtitle: subtitle,
      child: summaryAsync.when(
        data: (summaries) {
          final candidates = buildCandidates(summaries);
          if (candidates.isEmpty) return const Text('No qualifying students yet.');
          return Column(
            children: candidates
                .map((c) => _CandidateRow(
                      candidate: c,
                      onAward: () => _logAward(context, ref, category: category, scopeType: 'student', studentId: c.studentId, range: range),
                    ))
                .toList(),
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (error, stackTrace) => Text('Failed to load: $error'),
      ),
    );
  }
}

class _ImprovementRewardSection extends ConsumerWidget {
  const _ImprovementRewardSection({required this.thisWeek, required this.lastWeek});

  final DateRange thisWeek;
  final DateRange lastWeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(studentPeriodSummaryProvider(thisWeek));
    final previousAsync = ref.watch(studentPeriodSummaryProvider(lastWeek));

    return _RewardCard(
      title: 'Peningkatan Individu',
      subtitle: 'Individual improvement (vs last week)',
      child: (currentAsync.isLoading || previousAsync.isLoading)
          ? const LinearProgressIndicator()
          : (currentAsync.hasError || previousAsync.hasError)
              ? Text('Failed to load: ${currentAsync.error ?? previousAsync.error}')
              : _buildCandidates(context, ref, currentAsync.requireValue, previousAsync.requireValue),
    );
  }

  Widget _buildCandidates(BuildContext context, WidgetRef ref, List<StudentPeriodSummary> current, List<StudentPeriodSummary> previous) {
    final previousById = {for (final s in previous) s.studentId: s.totalPoints};
    final improvements = current
        .map((s) => (student: s, delta: s.totalPoints - (previousById[s.studentId] ?? 0)))
        .where((e) => e.delta > 0)
        .toList()
      ..sort((a, b) => b.delta.compareTo(a.delta));
    final top = improvements.take(5).toList();

    if (top.isEmpty) return const Text('No improvement to show yet.');
    return Column(
      children: top
          .map((e) => _CandidateRow(
                candidate: _Candidate(name: e.student.fullName, metric: '+${e.delta} pts this week', studentId: e.student.studentId),
                onAward: () => _logAward(
                  context,
                  ref,
                  category: MeritAwardCategory.individualImprovement,
                  scopeType: 'student',
                  studentId: e.student.studentId,
                  range: thisWeek,
                ),
              ))
          .toList(),
    );
  }
}

class _ClassRewardSection extends ConsumerWidget {
  const _ClassRewardSection({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.range,
    this.compareRange,
    this.sortByImprovement = false,
    this.metricBuilder,
    this.sortAscendingBy,
  });

  final String title;
  final String subtitle;
  final MeritAwardCategory category;
  final DateRange range;
  final DateRange? compareRange;
  final bool sortByImprovement;
  final String Function(ClassPeriodSummary)? metricBuilder;
  final double Function(ClassPeriodSummary)? sortAscendingBy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(classPeriodSummaryProvider(range));
    final previousAsync = compareRange == null ? null : ref.watch(classPeriodSummaryProvider(compareRange!));

    if (previousAsync != null) {
      return _RewardCard(
        title: title,
        subtitle: subtitle,
        child: (currentAsync.isLoading || previousAsync.isLoading)
            ? const LinearProgressIndicator()
            : (currentAsync.hasError || previousAsync.hasError)
                ? Text('Failed to load: ${currentAsync.error ?? previousAsync.error}')
                : _buildImprovement(context, ref, currentAsync.requireValue, previousAsync.requireValue),
      );
    }

    return _RewardCard(
      title: title,
      subtitle: subtitle,
      child: currentAsync.when(
        data: (classes) => _buildRanked(context, ref, classes),
        loading: () => const LinearProgressIndicator(),
        error: (error, stackTrace) => Text('Failed to load: $error'),
      ),
    );
  }

  Widget _buildImprovement(BuildContext context, WidgetRef ref, List<ClassPeriodSummary> current, List<ClassPeriodSummary> previous) {
    final previousById = {for (final c in previous) c.classId: c.pct};
    final improvements = current
        .map((c) => (cls: c, delta: c.pct - (previousById[c.classId] ?? 0)))
        .where((e) => e.delta > 0)
        .toList()
      ..sort((a, b) => b.delta.compareTo(a.delta));
    final top = improvements.take(3).toList();
    if (top.isEmpty) return const Text('No improvement to show yet.');
    return Column(
      children: top
          .map((e) => _CandidateRow(
                candidate: _Candidate(name: e.cls.className, metric: '+${e.delta.toStringAsFixed(1)}% this week', classId: e.cls.classId),
                onAward: () => _logAward(context, ref, category: category, scopeType: 'class', classId: e.cls.classId, range: range),
              ))
          .toList(),
    );
  }

  Widget _buildRanked(BuildContext context, WidgetRef ref, List<ClassPeriodSummary> classes) {
    if (classes.isEmpty) return const Text('No merit records for this period yet.');
    final sorted = [...classes];
    if (sortAscendingBy != null) {
      sorted.sort((a, b) => sortAscendingBy!(a).compareTo(sortAscendingBy!(b)));
    } else {
      sorted.sort((a, b) => b.pct.compareTo(a.pct));
    }
    final top = sorted.take(3).toList();
    return Column(
      children: top
          .map((c) => _CandidateRow(
                candidate: _Candidate(
                  name: c.className,
                  metric: metricBuilder?.call(c) ?? '${c.pct.toStringAsFixed(1)}% (${c.totalPoints}/${c.maxPoints})',
                  classId: c.classId,
                ),
                onAward: () => _logAward(context, ref, category: category, scopeType: 'class', classId: c.classId, range: range),
              ))
          .toList(),
    );
  }
}
