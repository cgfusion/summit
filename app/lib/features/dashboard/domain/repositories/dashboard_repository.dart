import '../entities/attendance_period_summary.dart';
import '../entities/chronic_latecomer.dart';
import '../entities/dashboard_analytics.dart';
import '../entities/leave_type_breakdown.dart';

abstract interface class DashboardRepository {
  Future<AttendanceDaySummary> getAttendanceDaySummary(DateTime date);

  Future<List<AttendanceTrendPoint>> getDailyAttendanceTrend({required DateTime from, required DateTime to});

  Future<List<MeritTrendPoint>> getDailyMeritTrend({required DateTime from, required DateTime to});

  Future<List<ClassAttendanceRow>> getClassAttendanceSummary({required DateTime from, required DateTime to});

  Future<List<StudentStreak>> getAttendanceStreaks({int limit = 10});

  Future<List<RecentActivityItem>> getRecentActivity({int limit = 15});

  Future<KpiOverview> getKpiOverview({required DateTime from, required DateTime to});

  /// Per-class + whole-school attendance rate for day/week/month/year, all
  /// anchored to [referenceDate].
  Future<List<AttendancePeriodSummary>> getAttendancePeriodSummary(DateTime referenceDate);

  /// Students with at least [minLate] 'lewat' days in the [windowDays]
  /// ending at [referenceDate].
  Future<List<ChronicLatecomer>> getChronicLatecomers({
    required DateTime referenceDate,
    int windowDays = 7,
    int minLate = 3,
  });

  Future<LeaveTypeBreakdown> getLeaveTypeBreakdown({required DateTime from, required DateTime to});
}
