import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/attendance_period_summary.dart';
import '../../domain/entities/chronic_latecomer.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/leave_type_breakdown.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<AttendanceDaySummary> getAttendanceDaySummary(DateTime date) async {
    final rows = await _client.rpc('fn_attendance_day_summary', params: {'p_date': _dateOnly(date)}) as List;
    if (rows.isEmpty) return AttendanceDaySummary.zero;
    return AttendanceDaySummary.fromMap(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<AttendanceTrendPoint>> getDailyAttendanceTrend({required DateTime from, required DateTime to}) async {
    final rows = await _client.rpc('fn_daily_attendance_trend', params: {
      'p_from': _dateOnly(from),
      'p_to': _dateOnly(to),
    }) as List;
    return rows.map((row) => AttendanceTrendPoint.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<MeritTrendPoint>> getDailyMeritTrend({required DateTime from, required DateTime to}) async {
    final rows = await _client.rpc('fn_daily_merit_trend', params: {
      'p_from': _dateOnly(from),
      'p_to': _dateOnly(to),
    }) as List;
    return rows.map((row) => MeritTrendPoint.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ClassAttendanceRow>> getClassAttendanceSummary({required DateTime from, required DateTime to}) async {
    final rows = await _client.rpc('fn_class_attendance_summary', params: {
      'p_from': _dateOnly(from),
      'p_to': _dateOnly(to),
    }) as List;
    return rows.map((row) => ClassAttendanceRow.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<StudentStreak>> getAttendanceStreaks({int limit = 10}) async {
    final rows = await _client.rpc('fn_attendance_streaks', params: {'p_limit': limit}) as List;
    return rows.map((row) => StudentStreak.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<RecentActivityItem>> getRecentActivity({int limit = 15}) async {
    final rows = await _client.rpc('fn_recent_activity', params: {'p_limit': limit}) as List;
    return rows.map((row) => RecentActivityItem.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<KpiOverview> getKpiOverview({required DateTime from, required DateTime to}) async {
    final rows = await _client.rpc('fn_kpi_overview', params: {
      'p_from': _dateOnly(from),
      'p_to': _dateOnly(to),
    }) as List;
    return KpiOverview.fromMap(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<AttendancePeriodSummary>> getAttendancePeriodSummary(DateTime referenceDate) async {
    final rows = await _client.rpc('fn_attendance_period_summary', params: {
      'p_reference_date': _dateOnly(referenceDate),
    }) as List;
    return rows.map((row) => AttendancePeriodSummary.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ChronicLatecomer>> getChronicLatecomers({
    required DateTime referenceDate,
    int windowDays = 7,
    int minLate = 3,
  }) async {
    final rows = await _client.rpc('fn_chronic_latecomers', params: {
      'p_reference_date': _dateOnly(referenceDate),
      'p_window_days': windowDays,
      'p_min_late': minLate,
    }) as List;
    return rows.map((row) => ChronicLatecomer.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<LeaveTypeBreakdown> getLeaveTypeBreakdown({required DateTime from, required DateTime to}) async {
    final rows = await _client.rpc('fn_leave_type_breakdown', params: {
      'p_from': _dateOnly(from),
      'p_to': _dateOnly(to),
    }) as List;
    return LeaveTypeBreakdown.fromMap(rows.first as Map<String, dynamic>);
  }

  String _dateOnly(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }
}
