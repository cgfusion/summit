import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../merit/presentation/providers/merit_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../student/presentation/providers/student_providers.dart';
import '../../../student/presentation/screens/student_detail_sheet.dart';
import '../../domain/entities/attendance_period_summary.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_layout.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_drill_down_sheets.dart';

const _statCatalog = <String, (IconData, String)>{
  'stat_attendance_today': (Icons.fact_check, 'Attendance Today'),
  'stat_present': (Icons.people, 'Present'),
  'stat_late': (Icons.access_time, 'Late'),
  'stat_absent': (Icons.person_off, 'Absent'),
  'stat_merit_points': (Icons.star, 'Merit Points Today'),
  'stat_rewards_issued': (Icons.card_giftcard, 'Rewards Issued'),
};

const _chartCatalog = <String, (IconData, String)>{
  'chart_attendance_trend': (Icons.show_chart, 'Attendance Trend (This Week)'),
  'chart_attendance_status': (Icons.donut_small, 'Attendance by Status (Today)'),
  'chart_attendance_by_time': (Icons.bar_chart, 'Attendance by Time (Today)'),
  'chart_streak_leaderboard': (Icons.local_fire_department, 'Top 10 Students (Current Streak)'),
  'chart_class_ranking': (Icons.leaderboard, 'Class Ranking (Attendance)'),
  'chart_merit_trend': (Icons.trending_up, 'Merit Points (This Week)'),
  'chart_merit_distribution': (Icons.pie_chart, 'Merit Distribution (This Month)'),
  'chart_attendance_heatmap': (Icons.calendar_view_month, 'Attendance Heatmap (This Month)'),
  'chart_recent_activity': (Icons.history, 'Recent Activity'),
  'chart_kpi_overview': (Icons.speed, 'KPI Overview (This Month)'),
};

DateTime _dateOnly(DateTime d) => dateOnly(d);

String _greeting(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 18) return 'Good Afternoon';
  return 'Good Evening';
}

/// A "nice" round axis interval (1/2/5 x a power of 10) for [maxValue], so
/// fl_chart's left-axis ticks land on clean numbers instead of overlapping
/// near the top when the default auto-interval doesn't divide evenly.
double _niceInterval(double maxValue) {
  if (maxValue <= 0) return 1;
  final rough = maxValue / 4;
  final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final residual = rough / magnitude;
  final niceResidual = residual <= 1
      ? 1.0
      : residual <= 2
          ? 2.0
          : residual <= 5
              ? 5.0
              : 10.0;
  return niceResidual * magnitude;
}

/// Builds every chart card once, then arranges them per [order] (falling
/// back to catalog order for any id that's missing, and appending a
/// "Worst 5 Classes" companion card right after Class Ranking when
/// [showWorstClasses] is on -- that companion isn't independently
/// reorderable since it's really a variant of the ranking card next to it).
List<Widget> _orderedChartCards({
  required BuildContext context,
  required List<String> order,
  required bool showWorstClasses,
  required ValueChanged<bool> onToggleWorstClasses,
  required DateTime today,
  required DateTime weekStart,
  required DateTime weekEnd,
  required DateTime monthStart,
  required DateTime monthEnd,
  required TextTheme textTheme,
}) {
  final cards = <String, Widget>{
    'chart_attendance_trend': _ChartCard(
      title: 'Attendance Trend (This Week)',
      child: _AttendanceTrendChart(from: weekStart, to: weekEnd),
    ),
    'chart_attendance_status': _ChartCard(
      title: 'Attendance by Status (Today)',
      onTap: () => showDashboardAttendanceDrillDown(
        context,
        date: today,
        title: 'Pecahan Kehadiran Hari Ini',
        initialStatusFilter: null,
      ),
      child: _AttendanceStatusDonut(date: today),
    ),
    'chart_attendance_by_time': _ChartCard(
      title: 'Attendance by Time (Today)',
      onTap: () => showDashboardAttendanceDrillDown(
        context,
        date: today,
        title: 'Masa Ketibaan Hari Ini',
        initialStatusFilter: null,
      ),
      child: _AttendanceByTimeChart(date: today),
    ),
    'chart_streak_leaderboard': const _ChartCard(title: 'Top 10 Students (Current Streak)', child: _StreakLeaderboard()),
    'chart_class_ranking': _ChartCard(
      title: 'Class Ranking (Attendance)',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Worst 5', style: textTheme.bodySmall),
          Switch(value: showWorstClasses, onChanged: onToggleWorstClasses),
        ],
      ),
      child: _ClassLeaderboard(from: monthStart, to: monthEnd, best: true, limit: null),
    ),
    'chart_merit_trend': _ChartCard(title: 'Merit Points (This Week)', child: _MeritTrendChart(from: weekStart, to: weekEnd)),
    'chart_merit_distribution': _ChartCard(
      title: 'Merit Distribution (This Month)',
      child: _MeritDistributionDonut(from: monthStart, to: monthEnd),
    ),
    'chart_attendance_heatmap': _ChartCard(title: 'Attendance Heatmap (This Month)', child: _AttendanceHeatmap(month: today)),
    'chart_recent_activity': const _ChartCard(title: 'Recent Activity', child: _RecentActivityList()),
    'chart_kpi_overview': _ChartCard(title: 'KPI Overview (This Month)', child: _KpiGauges(from: monthStart, to: monthEnd)),
  };

  final ids = order.where(cards.containsKey).toList();
  for (final id in cards.keys) {
    if (!ids.contains(id)) ids.add(id);
  }
  if (showWorstClasses) {
    final index = ids.indexOf('chart_class_ranking');
    ids.insert(index == -1 ? ids.length : index + 1, 'chart_class_ranking_worst5');
  }

  return ids.map((id) {
    if (id == 'chart_class_ranking_worst5') {
      return _ChartCard(
        title: 'Worst 5 Classes (Attendance)',
        child: _ClassLeaderboard(from: monthStart, to: monthEnd, best: false, limit: 5),
      );
    }
    return cards[id]!;
  }).toList();
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutMode = ref.watch(layoutModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final showWorstClasses = ref.watch(showWorstClassesProvider);
    final referenceDateOverride = ref.watch(dashboardReferenceDateProvider);
    final today = _dateOnly(referenceDateOverride ?? DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 4));
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = ref.watch(currentProfileProvider).value?.fullName.split(' ').first ?? 'Admin';
    final layout = ref.watch(dashboardLayoutControllerProvider).value ?? DashboardLayout.defaultLayout;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeBackButton(),
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
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: 'Rearrange Dashboard',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) => const _RearrangeDashboardSheet(),
            ),
          ),
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
          _AccountMenuButton(name: firstName),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: isDark ? const BoxDecoration(gradient: AppTheme.darkPageGradient) : null,
        child: LayoutBuilder(
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
                  _GreetingHeader(name: firstName, referenceDate: today),
                  const SizedBox(height: 16),
                  _MissingAttendanceBanner(date: today),
                  const SizedBox(height: 16),
                  _TopStatsRow(today: today, order: layout.statsOrder),
                  const SizedBox(height: 16),
                  _DashboardGrid(
                    columns: columns,
                    children: _orderedChartCards(
                      context: context,
                      order: layout.chartsOrder,
                      showWorstClasses: showWorstClasses,
                      onToggleWorstClasses: (v) => ref.read(showWorstClassesProvider.notifier).state = v,
                      today: today,
                      weekStart: weekStart,
                      weekEnd: weekEnd,
                      monthStart: monthStart,
                      monthEnd: monthEnd,
                      textTheme: Theme.of(context).textTheme,
                    ),
                  ),
                  const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: _ChartCard(
                    title: 'School Attendance Summary',
                    child: _SchoolAttendanceSummary(referenceDate: today),
                  ),
                ),
              ],
            ),
          );
          },
        ),
      ),
    );
  }
}

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader({required this.name, required this.referenceDate});

  final String name;
  final DateTime referenceDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(dashboardReferenceDateProvider);
    final isToday = override == null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting(DateTime.now())}, $name! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                "Here's what's happening at school today.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.filter_alt_outlined, size: 18),
          label: Text(isToday ? 'Today, ${DateFormat('d MMM').format(referenceDate)}' : DateFormat('d MMM yyyy').format(referenceDate)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: referenceDate,
              firstDate: DateTime(2025),
              lastDate: DateTime(2030),
            );
            if (picked != null) ref.read(dashboardReferenceDateProvider.notifier).state = _dateOnly(picked);
          },
        ),
        if (!isToday) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Back to today',
            onPressed: () => ref.read(dashboardReferenceDateProvider.notifier).state = null,
          ),
        ],
      ],
    );
  }
}

class _AccountMenuButton extends ConsumerWidget {
  const _AccountMenuButton({required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final colorScheme = Theme.of(context).colorScheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return PopupMenuButton<String>(
      tooltip: 'Account',
      onSelected: (value) {
        switch (value) {
          case 'signout':
            ref.read(supabaseClientProvider).auth.signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(enabled: false, child: Text(profile?.role ?? '', style: Theme.of(context).textTheme.bodySmall)),
        const PopupMenuItem(value: 'signout', child: ListTile(leading: Icon(Icons.logout), title: Text('Sign out'))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(initial, style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Lets the user drag stat cards and chart cards into their preferred order.
/// Reorders apply immediately (optimistic local state via
/// [DashboardLayoutController]) and persist to Supabase in the background.
class _RearrangeDashboardSheet extends ConsumerWidget {
  const _RearrangeDashboardSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(dashboardLayoutControllerProvider).value ?? DashboardLayout.defaultLayout;
    final controller = ref.read(dashboardLayoutControllerProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Rearrange Dashboard', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  TextButton(
                    onPressed: controller.resetToDefault,
                    child: const Text('Reset to Default'),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text('Stat Cards', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  _CatalogOrderList(
                    ids: layout.statsOrder,
                    catalog: _statCatalog,
                    onMove: controller.reorderStats,
                  ),
                  const SizedBox(height: 20),
                  Text('Chart Cards', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  _CatalogOrderList(
                    ids: layout.chartsOrder,
                    catalog: _chartCatalog,
                    onMove: controller.reorderCharts,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Both a drag handle (for desktop/Android, where pointer-down-initiated
/// dragging works reliably) and up/down move buttons (guaranteed to work
/// everywhere, including iPad Safari -- ReorderableListView's default drag
/// handle only renders on platforms it detects as "desktop", so on
/// touch/web it silently falls back to whole-tile long-press dragging,
/// which loses the gesture race against this list's scrollable ancestor
/// and shows no handle at all). Forcing [ReorderableListView.buildDefaultDragHandles]
/// on keeps the explicit handle available everywhere it can help, while the
/// buttons cover everywhere it can't.
class _CatalogOrderList extends StatelessWidget {
  const _CatalogOrderList({required this.ids, required this.catalog, required this.onMove});

  final List<String> ids;
  final Map<String, (IconData, String)> catalog;
  final void Function(int oldIndex, int newIndex) onMove;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: true,
      onReorderItem: onMove,
      children: [
        for (var i = 0; i < ids.length; i++)
          if (catalog[ids[i]] case (final icon, final label))
            ListTile(
              key: ValueKey(ids[i]),
              leading: Icon(icon),
              title: Text(label),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: 'Move up',
                    onPressed: i == 0 ? null : () => onMove(i, i - 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    tooltip: 'Move down',
                    onPressed: i == ids.length - 1 ? null : () => onMove(i, i + 1),
                  ),
                ],
              ),
            ),
      ],
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
  const _ChartCard({required this.title, required this.child, this.trailing, this.onTap});

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  if (onTap != null)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top stat row
// ---------------------------------------------------------------------------

class _TopStatsRow extends ConsumerWidget {
  const _TopStatsRow({required this.today, required this.order});

  final DateTime today;
  final List<String> order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yesterday = today.subtract(const Duration(days: 1));
    final todayAsync = ref.watch(attendanceDaySummaryProvider(today));
    final yesterdayAsync = ref.watch(attendanceDaySummaryProvider(yesterday));

    final t = todayAsync.value ?? AttendanceDaySummary.zero;
    final y = yesterdayAsync.value ?? AttendanceDaySummary.zero;
    final loading = todayAsync.isLoading || yesterdayAsync.isLoading;

    final todayRate = t.recordedCount == 0 ? 0.0 : (t.recordedCount - t.absentCount) / t.recordedCount * 100;
    final yesterdayRate = y.recordedCount == 0 ? 0.0 : (y.recordedCount - y.absentCount) / y.recordedCount * 100;

    final cards = <String, Widget>{
      'stat_attendance_today': _StatCard(
        icon: Icons.fact_check,
        color: Colors.green,
        label: 'Attendance Today',
        value: '${todayRate.toStringAsFixed(1)}%',
        delta: todayRate - yesterdayRate,
        deltaSuffix: 'pts',
        loading: loading,
        onTap: () => showDashboardAttendanceDrillDown(
          context,
          date: today,
          title: 'Senarai Kehadiran Hari Ini',
          initialStatusFilter: null,
        ),
      ),
      'stat_present': _StatCard(
        icon: Icons.people,
        color: Colors.blue,
        label: 'Present',
        value: '${t.presentCount}',
        delta: (t.presentCount - y.presentCount).toDouble(),
        loading: loading,
        onTap: () => showDashboardAttendanceDrillDown(
          context,
          date: today,
          title: 'Senarai Murid Hadir Hari Ini',
          initialStatusFilter: 'hadir',
        ),
      ),
      'stat_late': _StatCard(
        icon: Icons.access_time,
        color: Colors.amber.shade800,
        label: 'Late',
        value: '${t.lateCount}',
        delta: (t.lateCount - y.lateCount).toDouble(),
        lowerIsBetter: true,
        loading: loading,
        onTap: () => showDashboardAttendanceDrillDown(
          context,
          date: today,
          title: 'Senarai Murid Lewat Hari Ini',
          initialStatusFilter: 'lewat',
        ),
      ),
      'stat_absent': _StatCard(
        icon: Icons.person_off,
        color: Colors.red,
        label: 'Absent',
        value: '${t.absentCount}',
        delta: (t.absentCount - y.absentCount).toDouble(),
        lowerIsBetter: true,
        loading: loading,
        onTap: () => showDashboardAttendanceDrillDown(
          context,
          date: today,
          title: 'Senarai Murid Tidak Hadir Hari Ini',
          initialStatusFilter: 'tidak_hadir',
        ),
      ),
      'stat_merit_points': _StatCard(
        icon: Icons.star,
        color: Colors.purple,
        label: 'Merit Points Today',
        value: '${t.meritPoints}',
        delta: (t.meritPoints - y.meritPoints).toDouble(),
        loading: loading,
        onTap: () => showDashboardAttendanceDrillDown(
          context,
          date: today,
          title: 'Senarai Murid Rekod Merit Hari Ini',
          initialStatusFilter: null,
        ),
      ),
      'stat_rewards_issued': _StatCard(
        icon: Icons.card_giftcard,
        color: Colors.pink,
        label: 'Rewards Issued',
        value: '${t.rewardsIssued}',
        delta: (t.rewardsIssued - y.rewardsIssued).toDouble(),
        loading: loading,
        onTap: () => showDashboardAttendanceDrillDown(
          context,
          date: today,
          title: 'Senarai Murid Ganjaran Diterima',
          initialStatusFilter: null,
        ),
      ),
    };
    final ids = order.where(cards.containsKey).toList();
    for (final id in cards.keys) {
      if (!ids.contains(id)) ids.add(id);
    }

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
            for (final id in ids) SizedBox(width: cardWidth, child: cards[id]),
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
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final double delta;
  final String deltaSuffix;
  final bool lowerIsBetter;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final improved = lowerIsBetter ? delta < 0 : delta > 0;
    final unchanged = delta == 0;
    final deltaColor = unchanged ? Colors.grey : (improved ? Colors.green : Colors.red);
    final arrow = unchanged ? Icons.remove : (delta > 0 ? Icons.arrow_upward : Icons.arrow_downward);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
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
      ),
    );

    if (!isDark) return card;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.glow(color)),
      child: card,
    );
  }
}

// ---------------------------------------------------------------------------
// Missing attendance banner -- compliance flag for classes not yet marked
// ---------------------------------------------------------------------------

class _MissingAttendanceBanner extends ConsumerWidget {
  const _MissingAttendanceBanner({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(classAttendanceSummaryProvider((from: date, to: date)));
    final rows = rowsAsync.value;
    if (rows == null) return const SizedBox.shrink();

    final missing = rows.where((r) => r.recordedCount == 0).toList()
      ..sort((a, b) => a.className.compareTo(b.className));
    if (missing.isEmpty) return const SizedBox.shrink();

    final color = Colors.orange.shade800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Card(
      color: isDark ? null : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${missing.length} class${missing.length == 1 ? '' : 'es'} with no attendance recorded today',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in missing)
                  Chip(
                    label: Text(r.className),
                    backgroundColor: color.withValues(alpha: isDark ? 0.18 : 0.12),
                    side: BorderSide(color: color.withValues(alpha: 0.4)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!isDark) return card;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.glow(color)),
      child: card,
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
                  interval: 1,
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
        final rawMax = (buckets.reduce((a, b) => a > b ? a : b)).toDouble();
        final interval = _niceInterval(rawMax == 0 ? 1 : rawMax);
        final maxY = rawMax == 0 ? interval : (rawMax / interval).ceil() * interval;
        final accent = Theme.of(context).colorScheme.primary;
        return BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(drawVerticalLine: false, horizontalInterval: interval),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: interval)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
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
              onTap: () async {
                final fullStudent = await ref.read(studentRepositoryProvider).getById(row.studentId);
                if (fullStudent != null && context.mounted) {
                  showStudentDetailSheet(context, fullStudent);
                }
              },
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
  const _LeaderboardRow({
    required this.rank,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final int rank;
  final String label;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (rank) {
      1 => Colors.amber,
      2 => Colors.blueGrey,
      3 => Colors.brown,
      _ => null,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Class leaderboards
// ---------------------------------------------------------------------------

class _ClassLeaderboard extends ConsumerWidget {
  const _ClassLeaderboard({required this.from, required this.to, required this.best, required this.limit});

  final DateTime from;
  final DateTime to;
  final bool best;

  /// Caps the list to this many rows; null shows every class with data.
  final int? limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(classAttendanceSummaryProvider((from: from, to: to)));
    return async.when(
      data: (rows) {
        final withData = rows.where((r) => r.recordedCount > 0).toList()
          ..sort((a, b) => best ? b.attendanceRate.compareTo(a.attendanceRate) : a.attendanceRate.compareTo(b.attendanceRate));
        final top = limit == null ? withData : withData.take(limit!).toList();
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
        final rawMax = points.map((p) => p.totalPoints).reduce((a, b) => a > b ? a : b).toDouble();
        final interval = _niceInterval(rawMax == 0 ? 1 : rawMax);
        final maxY = rawMax == 0 ? interval : (rawMax / interval).ceil() * interval;
        final accent = Colors.purple;
        return BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(drawVerticalLine: false, horizontalInterval: interval),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: interval)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
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
          if (week.any((d) => d != null)) weeks.add(week);
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

/// Compact day/week/month/year school-wide attendance rate. Week/month/year
/// use the full period's school-day count as denominator (not days elapsed
/// so far), so it reads as progress-so-far and only reaches its final value
/// at period end -- see fn_attendance_period_summary. The full per-class
/// breakdown lives on Class Summary.
class _SchoolAttendanceSummary extends ConsumerWidget {
  const _SchoolAttendanceSummary({required this.referenceDate});

  final DateTime referenceDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attendancePeriodSummaryProvider(referenceDate));
    return async.when(
      data: (rows) {
        final schoolRows = rows.where((r) => r.scope == AttendanceSummaryScope.school);
        if (schoolRows.isEmpty) return const _EmptyState(message: 'No attendance data yet.');
        final school = schoolRows.first;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SummaryStat(label: 'Day', value: school.dayRate),
            _SummaryStat(label: 'Week', value: school.weekRate),
            _SummaryStat(label: 'Month', value: school.monthRate),
            _SummaryStat(label: 'Year', value: school.yearRate),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(message: 'Failed to load: $error'),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value%', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ],
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
