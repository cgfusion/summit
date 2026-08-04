import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../merit/presentation/providers/merit_providers.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../providers/dashboard_providers.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutMode = ref.watch(layoutModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final today = _dateOnly(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 4));
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset('assets/images/crest.png', width: 28, height: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'DARE TO CHANGE (D2C)',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        titleSpacing: 16,
        actions: [
          IconButton(
            icon: Icon(AppTheme.iconFor(themeMode)),
            tooltip: 'Theme: ${AppTheme.labelFor(themeMode)}',
            onPressed: () => ref.read(themeModeProvider.notifier).state = AppTheme.nextThemeMode(themeMode),
          ),
          IconButton(
            icon: Icon(AppShell.iconFor(layoutMode)),
            tooltip: 'Layout: ${layoutMode.name}',
            onPressed: () => ref.read(layoutModeProvider.notifier).state = AppShell.next(layoutMode),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(supabaseClientProvider).auth.signOut(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1300
              ? 4
              : constraints.maxWidth >= 950
                  ? 3
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopStatsRow(today: today),
                const SizedBox(height: 16),
                _DashboardGrid(
                  columns: columns,
                  children: [
                    _ChartCard(title: 'Attendance Trend (This Week)', child: _AttendanceTrendChart(from: weekStart, to: weekEnd)),
                    _ChartCard(title: 'Attendance by Status (Today)', child: _AttendanceStatusDonut(date: today)),
                    _ChartCard(title: 'Attendance by Time (Today)', child: _AttendanceByTimeChart(date: today)),
                    const _ChartCard(title: 'Top 10 Students (Current Streak)', child: _StreakLeaderboard()),
                  ],
                ),
                const SizedBox(height: 16),
                _DashboardGrid(
                  columns: columns,
                  children: [
                    _ChartCard(
                      title: 'Top 5 Classes (Attendance)',
                      child: _ClassLeaderboard(from: monthStart, to: monthEnd, best: true),
                    ),
                    _ChartCard(
                      title: 'Worst 5 Classes (Attendance)',
                      child: _ClassLeaderboard(from: monthStart, to: monthEnd, best: false),
                    ),
                    _ChartCard(title: 'Merit Points (This Week)', child: _MeritTrendChart(from: weekStart, to: weekEnd)),
                    _ChartCard(
                      title: 'Merit Distribution (This Month)',
                      child: _MeritDistributionDonut(from: monthStart, to: monthEnd),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DashboardGrid(
                  columns: columns < 3 ? columns : 3,
                  children: [
                    _ChartCard(title: 'Attendance Heatmap (This Month)', child: _AttendanceHeatmap(month: today)),
                    const _ChartCard(title: 'Recent Activity', child: _RecentActivityList()),
                    _ChartCard(title: 'KPI Overview (This Month)', child: _KpiGauges(from: monthStart, to: monthEnd)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: children,
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top stat row
// ---------------------------------------------------------------------------

class _TopStatsRow extends ConsumerWidget {
  const _TopStatsRow({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yesterday = today.subtract(const Duration(days: 1));
    final todayAsync = ref.watch(attendanceDaySummaryProvider(today));
    final yesterdayAsync = ref.watch(attendanceDaySummaryProvider(yesterday));

    final t = todayAsync.value ?? AttendanceDaySummary.zero;
    final y = yesterdayAsync.value ?? AttendanceDaySummary.zero;
    final loading = todayAsync.isLoading || yesterdayAsync.isLoading;

    final todayRate = t.recordedCount == 0 ? 0.0 : (t.presentCount + t.lateCount) / t.recordedCount * 100;
    final yesterdayRate = y.recordedCount == 0 ? 0.0 : (y.presentCount + y.lateCount) / y.recordedCount * 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth >= 1300
            ? 6
            : constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 500
                    ? 2
                    : 1;
        final cardWidth = (constraints.maxWidth - (perRow - 1) * 12) / perRow;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                icon: Icons.fact_check,
                color: Colors.green,
                label: 'Attendance Today',
                value: '${todayRate.toStringAsFixed(1)}%',
                delta: todayRate - yesterdayRate,
                deltaSuffix: 'pts',
                loading: loading,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                icon: Icons.people,
                color: Colors.blue,
                label: 'Present',
                value: '${t.presentCount}',
                delta: (t.presentCount - y.presentCount).toDouble(),
                loading: loading,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                icon: Icons.access_time,
                color: Colors.amber.shade800,
                label: 'Late',
                value: '${t.lateCount}',
                delta: (t.lateCount - y.lateCount).toDouble(),
                lowerIsBetter: true,
                loading: loading,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                icon: Icons.person_off,
                color: Colors.red,
                label: 'Absent',
                value: '${t.absentCount}',
                delta: (t.absentCount - y.absentCount).toDouble(),
                lowerIsBetter: true,
                loading: loading,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                icon: Icons.star,
                color: Colors.purple,
                label: 'Merit Points Today',
                value: '${t.meritPoints}',
                delta: (t.meritPoints - y.meritPoints).toDouble(),
                loading: loading,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                icon: Icons.card_giftcard,
                color: Colors.pink,
                label: 'Rewards Issued',
                value: '${t.rewardsIssued}',
                delta: (t.rewardsIssued - y.rewardsIssued).toDouble(),
                loading: loading,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.delta,
    this.deltaSuffix = '',
    this.lowerIsBetter = false,
    this.loading = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final double delta;
  final String deltaSuffix;
  final bool lowerIsBetter;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final improved = lowerIsBetter ? delta < 0 : delta > 0;
    final unchanged = delta == 0;
    final deltaColor = unchanged ? Colors.grey : (improved ? Colors.green : Colors.red);
    final arrow = unchanged ? Icons.remove : (delta > 0 ? Icons.arrow_upward : Icons.arrow_downward);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            loading
                ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (!loading)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(arrow, size: 12, color: deltaColor),
                  const SizedBox(width: 2),
                  Text(
                    '${delta.abs().toStringAsFixed(delta.abs() == delta.abs().roundToDouble() ? 0 : 1)}$deltaSuffix vs yesterday',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: deltaColor),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance trend (line)
// ---------------------------------------------------------------------------

class _AttendanceTrendChart extends ConsumerWidget {
  const _AttendanceTrendChart({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyAttendanceTrendProvider((from: from, to: to)));
    return async.when(
      data: (points) {
        if (points.isEmpty) return const _EmptyState(message: 'No attendance recorded this week yet.');
        final spots = [
          for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].attendanceRate),
        ];
        final accent = Theme.of(context).colorScheme.primary;
        return LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: const FlGridData(drawVerticalLine: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 25)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= points.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(DateFormat('E').format(points[i].schoolDate), style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: accent,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: accent.withValues(alpha: 0.12)),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance by status (donut)
// ---------------------------------------------------------------------------

class _AttendanceStatusDonut extends ConsumerWidget {
  const _AttendanceStatusDonut({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attendanceDaySummaryProvider(date));
    return async.when(
      data: (s) {
        if (s.recordedCount == 0) return const _EmptyState(message: 'No attendance recorded today yet.');
        return Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 36,
                  sectionsSpace: 2,
                  sections: [
                    if (s.presentCount > 0)
                      PieChartSectionData(value: s.presentCount.toDouble(), color: Colors.green, showTitle: false, radius: 26),
                    if (s.lateCount > 0)
                      PieChartSectionData(value: s.lateCount.toDouble(), color: Colors.amber, showTitle: false, radius: 26),
                    if (s.absentCount > 0)
                      PieChartSectionData(value: s.absentCount.toDouble(), color: Colors.red, showTitle: false, radius: 26),
                    if (s.mcCount > 0)
                      PieChartSectionData(value: s.mcCount.toDouble(), color: Colors.blueGrey, showTitle: false, radius: 26),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendDot(color: Colors.green, label: 'Present', value: s.presentCount),
                _LegendDot(color: Colors.amber, label: 'Late', value: s.lateCount),
                _LegendDot(color: Colors.red, label: 'Absent', value: s.absentCount),
                _LegendDot(color: Colors.blueGrey, label: 'MC', value: s.mcCount),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label ($value)', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance by time-of-scan (bar)
// ---------------------------------------------------------------------------

class _AttendanceByTimeChart extends ConsumerWidget {
  const _AttendanceByTimeChart({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attendanceForDateAllProvider(date));
    return async.when(
      data: (rows) {
        final scanned = rows.where((r) => r.firstScanAt != null).toList();
        if (scanned.isEmpty) return const _EmptyState(message: 'No scans recorded today yet.');
        var before715 = 0, r715to730 = 0, r730to745 = 0, after745 = 0;
        for (final row in scanned) {
          final local = row.firstScanAt!.toLocal();
          final minutes = local.hour * 60 + local.minute;
          if (minutes < 7 * 60 + 15) {
            before715++;
          } else if (minutes < 7 * 60 + 30) {
            r715to730++;
          } else if (minutes < 7 * 60 + 45) {
            r730to745++;
          } else {
            after745++;
          }
        }
        final buckets = [before715, r715to730, r730to745, after745];
        final labels = ['<7:15', '7:15-7:30', '7:30-7:45', '>7:45'];
        final maxY = (buckets.reduce((a, b) => a > b ? a : b)).toDouble();
        final accent = Theme.of(context).colorScheme.primary;
        return BarChart(
          BarChartData(
            maxY: maxY == 0 ? 1 : maxY * 1.2,
            gridData: const FlGridData(drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(labels[i], style: const TextStyle(fontSize: 9)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < buckets.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [BarChartRodData(toY: buckets[i].toDouble(), color: accent, width: 22, borderRadius: BorderRadius.circular(4))],
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak leaderboard
// ---------------------------------------------------------------------------

class _StreakLeaderboard extends ConsumerWidget {
  const _StreakLeaderboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attendanceStreaksProvider);
    return async.when(
      data: (rows) {
        if (rows.isEmpty) return const _EmptyState(message: 'No streak data yet.');
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            return _LeaderboardRow(
              rank: index + 1,
              label: row.fullName,
              trailing: '${row.streakDays} day${row.streakDays == 1 ? '' : 's'}',
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.label, required this.trailing});

  final int rank;
  final String label;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (rank) {
      1 => Colors.amber,
      2 => Colors.blueGrey,
      3 => Colors.brown,
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: medalColor != null
                ? Icon(Icons.emoji_events, size: 16, color: medalColor)
                : Text('$rank', style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(trailing, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Class leaderboards
// ---------------------------------------------------------------------------

class _ClassLeaderboard extends ConsumerWidget {
  const _ClassLeaderboard({required this.from, required this.to, required this.best});

  final DateTime from;
  final DateTime to;
  final bool best;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(classAttendanceSummaryProvider((from: from, to: to)));
    return async.when(
      data: (rows) {
        final withData = rows.where((r) => r.recordedCount > 0).toList()
          ..sort((a, b) => best ? b.attendanceRate.compareTo(a.attendanceRate) : a.attendanceRate.compareTo(b.attendanceRate));
        final top = withData.take(5).toList();
        if (top.isEmpty) return const _EmptyState(message: 'No attendance recorded this month yet.');
        return ListView.builder(
          itemCount: top.length,
          itemBuilder: (context, index) {
            final row = top[index];
            return _LeaderboardRow(rank: index + 1, label: row.className, trailing: '${row.attendanceRate}%');
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

// ---------------------------------------------------------------------------
// Merit points trend (bar)
// ---------------------------------------------------------------------------

class _MeritTrendChart extends ConsumerWidget {
  const _MeritTrendChart({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyMeritTrendProvider((from: from, to: to)));
    return async.when(
      data: (points) {
        if (points.isEmpty) return const _EmptyState(message: 'No merit points this week yet.');
        final maxY = points.map((p) => p.totalPoints).reduce((a, b) => a > b ? a : b).toDouble();
        final accent = Colors.purple;
        return BarChart(
          BarChartData(
            maxY: maxY == 0 ? 1 : maxY * 1.2,
            gridData: const FlGridData(drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= points.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(DateFormat('E').format(points[i].schoolDate), style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < points.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: points[i].totalPoints.toDouble(),
                      color: accent,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

// ---------------------------------------------------------------------------
// Merit distribution (donut)
// ---------------------------------------------------------------------------

class _MeritDistributionDonut extends ConsumerWidget {
  const _MeritDistributionDonut({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentPeriodSummaryProvider((from: from, to: to)));
    return async.when(
      data: (rows) {
        final withData = rows.where((r) => r.maxPoints > 0).toList();
        if (withData.isEmpty) return const _EmptyState(message: 'No merit data this month yet.');
        var excellent = 0, good = 0, average = 0, low = 0;
        for (final r in withData) {
          if (r.pct >= 80) {
            excellent++;
          } else if (r.pct >= 60) {
            good++;
          } else if (r.pct >= 40) {
            average++;
          } else {
            low++;
          }
        }
        return Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 36,
                  sectionsSpace: 2,
                  sections: [
                    if (excellent > 0) PieChartSectionData(value: excellent.toDouble(), color: Colors.green, showTitle: false, radius: 26),
                    if (good > 0) PieChartSectionData(value: good.toDouble(), color: Colors.lightBlue, showTitle: false, radius: 26),
                    if (average > 0) PieChartSectionData(value: average.toDouble(), color: Colors.amber, showTitle: false, radius: 26),
                    if (low > 0) PieChartSectionData(value: low.toDouble(), color: Colors.red, showTitle: false, radius: 26),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendDot(color: Colors.green, label: 'Excellent (80+)', value: excellent),
                _LegendDot(color: Colors.lightBlue, label: 'Good (60-79)', value: good),
                _LegendDot(color: Colors.amber, label: 'Average (40-59)', value: average),
                _LegendDot(color: Colors.red, label: 'Low (0-39)', value: low),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance heatmap (calendar-by-weekday)
// ---------------------------------------------------------------------------

class _AttendanceHeatmap extends ConsumerWidget {
  const _AttendanceHeatmap({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    final async = ref.watch(dailyAttendanceTrendProvider((from: from, to: to)));
    return async.when(
      data: (points) {
        final byDate = {for (final p in points) _dateOnly(p.schoolDate): p};
        final weeks = <List<DateTime?>>[];
        var cursor = from.subtract(Duration(days: from.weekday - 1));
        while (!cursor.isAfter(to)) {
          final week = <DateTime?>[];
          for (var i = 0; i < 5; i++) {
            final d = cursor.add(Duration(days: i));
            week.add(d.month == month.month ? d : null);
          }
          weeks.add(week);
          cursor = cursor.add(const Duration(days: 7));
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  SizedBox(width: 32),
                  _WeekdayLabel('M'),
                  _WeekdayLabel('T'),
                  _WeekdayLabel('W'),
                  _WeekdayLabel('T'),
                  _WeekdayLabel('F'),
                ],
              ),
              for (final week in weeks)
                Row(
                  children: [
                    SizedBox(width: 32, child: Text(DateFormat('d').format(week.firstWhere((d) => d != null) ?? from), style: const TextStyle(fontSize: 9))),
                    for (final day in week) _HeatCell(rate: day == null ? null : byDate[day]?.attendanceRate),
                  ],
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: const [
                  _HeatLegend(color: Color(0xFF2F9E44), label: '90-100%'),
                  _HeatLegend(color: Color(0xFF74B816), label: '75-89%'),
                  _HeatLegend(color: Color(0xFFE8A400), label: '60-74%'),
                  _HeatLegend(color: Color(0xFFE03131), label: '<60%'),
                  _HeatLegend(color: Color(0xFFCED4DA), label: 'No data'),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 26, child: Center(child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))));
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.rate});
  final double? rate;

  @override
  Widget build(BuildContext context) {
    final r = rate;
    final color = r == null
        ? const Color(0xFFCED4DA)
        : r >= 90
            ? const Color(0xFF2F9E44)
            : r >= 75
                ? const Color(0xFF74B816)
                : r >= 60
                    ? const Color(0xFFE8A400)
                    : const Color(0xFFE03131);
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(color: color.withValues(alpha: rate == null ? 0.4 : 1), borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recent activity
// ---------------------------------------------------------------------------

class _RecentActivityList extends ConsumerWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentActivityProvider);
    return async.when(
      data: (rows) {
        if (rows.isEmpty) return const _EmptyState(message: 'No recent activity.');
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final item = rows[index];
            final (icon, color) = switch (item.kind) {
              ActivityKind.scan => (Icons.qr_code_scanner, Colors.indigo),
              ActivityKind.manualAttendance => (Icons.edit_calendar, Colors.orange),
              ActivityKind.meritAward => (Icons.emoji_events, Colors.pink),
            };
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.studentName ?? item.className ?? '-'} • ${item.detail}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('d MMM, HH:mm').format(item.occurredAt.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

// ---------------------------------------------------------------------------
// KPI gauges
// ---------------------------------------------------------------------------

class _KpiGauges extends ConsumerWidget {
  const _KpiGauges({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(kpiOverviewProvider((from: from, to: to)));
    return async.when(
      data: (kpi) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Gauge(label: 'Attendance', value: kpi.attendanceRate, target: 90, color: Colors.green),
            _Gauge(label: 'Merit Avg', value: kpi.meritAvgPct, target: 75, color: Colors.purple),
            _Gauge(label: 'Discipline', value: kpi.disciplineRate, target: 90, color: Colors.indigo),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.label, required this.value, required this.target, required this.color});

  final String label;
  final double value;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: (value / 100).clamp(0, 1),
                  strokeWidth: 7,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text('${value.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text('Target: ${target.toInt()}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
    );
  }
}
