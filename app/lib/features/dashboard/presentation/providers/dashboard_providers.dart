import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../attendance/domain/entities/attendance_day.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../merit/domain/value_objects/date_range.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

/// Whether the Dashboard's separate "Worst 5 Classes" card is shown, on top
/// of the always-visible full class ranking. Off by default; local UI
/// preference only, not persisted.
final showWorstClassesProvider = StateProvider<bool>((ref) => false);

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
}
