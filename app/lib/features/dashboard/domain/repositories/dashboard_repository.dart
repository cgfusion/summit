import '../entities/dashboard_analytics.dart';

abstract interface class DashboardRepository {
  Future<AttendanceDaySummary> getAttendanceDaySummary(DateTime date);

  Future<List<AttendanceTrendPoint>> getDailyAttendanceTrend({required DateTime from, required DateTime to});

  Future<List<MeritTrendPoint>> getDailyMeritTrend({required DateTime from, required DateTime to});

  Future<List<ClassAttendanceRow>> getClassAttendanceSummary({required DateTime from, required DateTime to});

  Future<List<StudentStreak>> getAttendanceStreaks({int limit = 10});

  Future<List<RecentActivityItem>> getRecentActivity({int limit = 15});

  Future<KpiOverview> getKpiOverview({required DateTime from, required DateTime to});
}
