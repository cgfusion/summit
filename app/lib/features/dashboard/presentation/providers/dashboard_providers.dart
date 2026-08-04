import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../attendance/domain/entities/attendance_day.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../merit/domain/value_objects/date_range.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/attendance_period_summary.dart';
import '../../domain/entities/chronic_latecomer.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_layout.dart';
import '../../domain/entities/leave_type_breakdown.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

/// Whether the Dashboard's separate "Worst 5 Classes" card is shown, on top
/// of the always-visible full class ranking. Off by default; local UI
/// preference only, not persisted.
final showWorstClassesProvider = StateProvider<bool>((ref) => false);

/// Overrides the Dashboard's "today" reference date via the header's Filter
/// button. Null means "use the real current date".
final dashboardReferenceDateProvider = StateProvider<DateTime?>((ref) => null);

/// All attendance_days rows for one date, school-wide -- deliberately
/// bypasses attendanceClassFilterProvider (the Attendance Status screen's
/// own filter state), same reasoning as the rest of this file.
final attendanceForDateAllProvider = FutureProvider.autoDispose.family<List<AttendanceDay>, DateTime>((ref, date) {
  return ref.watch(attendanceRepositoryProvider).getAttendanceForDate(date: date);
});

final attendanceDaySummaryProvider = FutureProvider.autoDispose.family<AttendanceDaySummary, DateTime>((ref, date) {
  return ref.watch(dashboardRepositoryProvider).getAttendanceDaySummary(date);
});

final dailyAttendanceTrendProvider = FutureProvider.autoDispose.family<List<AttendanceTrendPoint>, DateRange>((
  ref,
  range,
) {
  return ref.watch(dashboardRepositoryProvider).getDailyAttendanceTrend(from: range.from, to: range.to);
});

final dailyMeritTrendProvider = FutureProvider.autoDispose.family<List<MeritTrendPoint>, DateRange>((ref, range) {
  return ref.watch(dashboardRepositoryProvider).getDailyMeritTrend(from: range.from, to: range.to);
});

final classAttendanceSummaryProvider = FutureProvider.autoDispose.family<List<ClassAttendanceRow>, DateRange>((
  ref,
  range,
) {
  return ref.watch(dashboardRepositoryProvider).getClassAttendanceSummary(from: range.from, to: range.to);
});

final attendanceStreaksProvider = FutureProvider.autoDispose<List<StudentStreak>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getAttendanceStreaks(limit: 10);
});

final recentActivityProvider = FutureProvider.autoDispose<List<RecentActivityItem>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getRecentActivity(limit: 12);
});

final kpiOverviewProvider = FutureProvider.autoDispose.family<KpiOverview, DateRange>((ref, range) {
  return ref.watch(dashboardRepositoryProvider).getKpiOverview(from: range.from, to: range.to);
});

final attendancePeriodSummaryProvider = FutureProvider.autoDispose.family<List<AttendancePeriodSummary>, DateTime>((
  ref,
  referenceDate,
) {
  return ref.watch(dashboardRepositoryProvider).getAttendancePeriodSummary(referenceDate);
});

typedef ChronicLatecomerQuery = ({DateTime referenceDate, int windowDays, int minLate});

final chronicLatecomersProvider = FutureProvider.autoDispose.family<List<ChronicLatecomer>, ChronicLatecomerQuery>((
  ref,
  query,
) {
  return ref.watch(dashboardRepositoryProvider).getChronicLatecomers(
        referenceDate: query.referenceDate,
        windowDays: query.windowDays,
        minLate: query.minLate,
      );
});

final leaveTypeBreakdownProvider = FutureProvider.autoDispose.family<LeaveTypeBreakdown, DateRange>((ref, range) {
  return ref.watch(dashboardRepositoryProvider).getLeaveTypeBreakdown(from: range.from, to: range.to);
});

/// Holds the signed-in user's Dashboard card order. Reorders update local
/// state immediately (so the drag feels instant) and persist to Supabase in
/// the background; a persist failure is silently retried on next load since
/// the local reorder already reflects what the user asked for.
class DashboardLayoutController extends StateNotifier<AsyncValue<DashboardLayout>> {
  DashboardLayoutController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final layout = await _ref.read(dashboardRepositoryProvider).getDashboardLayout();
      state = AsyncValue.data(layout);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reorderStats(int oldIndex, int newIndex) {
    final current = state.value;
    if (current == null) return;
    _apply(current.copyWith(statsOrder: _moved(current.statsOrder, oldIndex, newIndex)));
  }

  void reorderCharts(int oldIndex, int newIndex) {
    final current = state.value;
    if (current == null) return;
    _apply(current.copyWith(chartsOrder: _moved(current.chartsOrder, oldIndex, newIndex)));
  }

  void resetToDefault() => _apply(DashboardLayout.defaultLayout);

  void _apply(DashboardLayout layout) {
    state = AsyncValue.data(layout);
    unawaited(_ref.read(dashboardRepositoryProvider).saveDashboardLayout(layout));
  }

  /// [oldIndex]/[newIndex] come from ReorderableListView's onReorderItem,
  /// which already adjusts newIndex for the removed item at oldIndex.
  List<String> _moved(List<String> list, int oldIndex, int newIndex) {
    final copy = [...list];
    copy.insert(newIndex, copy.removeAt(oldIndex));
    return copy;
  }
}

final dashboardLayoutControllerProvider =
    StateNotifierProvider.autoDispose<DashboardLayoutController, AsyncValue<DashboardLayout>>((ref) {
  return DashboardLayoutController(ref);
});

/// Invalidates every dashboard analytics provider -- call after any write
/// that could change attendance/merit/reward figures (manual attendance,
/// merit edits, awards) so the Dashboard reflects it next time it's shown.
void invalidateDashboardAnalytics(WidgetRef ref) {
  ref.invalidate(attendanceDaySummaryProvider);
  ref.invalidate(dailyAttendanceTrendProvider);
  ref.invalidate(dailyMeritTrendProvider);
  ref.invalidate(classAttendanceSummaryProvider);
  ref.invalidate(attendanceStreaksProvider);
  ref.invalidate(recentActivityProvider);
  ref.invalidate(kpiOverviewProvider);
  ref.invalidate(attendancePeriodSummaryProvider);
  ref.invalidate(chronicLatecomersProvider);
  ref.invalidate(leaveTypeBreakdownProvider);
}
