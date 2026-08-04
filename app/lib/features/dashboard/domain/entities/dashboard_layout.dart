/// A user's custom card order for the Dashboard's top stat row and chart
/// grid, persisted server-side so it follows them to any device.
class DashboardLayout {
  const DashboardLayout({required this.statsOrder, required this.chartsOrder});

  final List<String> statsOrder;
  final List<String> chartsOrder;

  static const defaultStatsOrder = [
    'stat_attendance_today',
    'stat_present',
    'stat_late',
    'stat_absent',
    'stat_merit_points',
    'stat_rewards_issued',
  ];

  static const defaultChartsOrder = [
    'chart_attendance_trend',
    'chart_attendance_status',
    'chart_attendance_by_time',
    'chart_streak_leaderboard',
    'chart_class_ranking',
    'chart_merit_trend',
    'chart_merit_distribution',
    'chart_attendance_heatmap',
    'chart_recent_activity',
    'chart_kpi_overview',
  ];

  static const defaultLayout = DashboardLayout(statsOrder: defaultStatsOrder, chartsOrder: defaultChartsOrder);

  /// [raw] is the `dashboard_layout` jsonb column -- null until the user
  /// customises their layout for the first time.
  factory DashboardLayout.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return defaultLayout;
    return DashboardLayout(
      statsOrder: _reconcile((raw['stats'] as List?)?.cast<String>(), defaultStatsOrder),
      chartsOrder: _reconcile((raw['charts'] as List?)?.cast<String>(), defaultChartsOrder),
    );
  }

  Map<String, dynamic> toMap() => {'stats': statsOrder, 'charts': chartsOrder};

  DashboardLayout copyWith({List<String>? statsOrder, List<String>? chartsOrder}) {
    return DashboardLayout(statsOrder: statsOrder ?? this.statsOrder, chartsOrder: chartsOrder ?? this.chartsOrder);
  }

  /// Drops ids no longer known (a card that's since been removed) and
  /// appends any known ids missing from [saved] (a card added after the
  /// user last customised their layout), so newly shipped cards still show
  /// up instead of silently disappearing.
  static List<String> _reconcile(List<String>? saved, List<String> known) {
    if (saved == null) return known;
    final keep = saved.where(known.contains).toList();
    final missing = known.where((id) => !keep.contains(id));
    return [...keep, ...missing];
  }
}
