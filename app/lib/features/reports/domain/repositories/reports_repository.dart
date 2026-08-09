import '../entities/kpi_trend_week.dart';
import '../entities/report_drill_down_entities.dart';

abstract interface class ReportsRepository {
  /// Weekly KPI trend per KK D2C.docx section 18.0. [session] filters to
  /// 'pagi'/'petang', or null for the whole school.
  Future<List<KpiTrendWeek>> getWeeklyKpiTrend({
    required DateTime from,
    required DateTime to,
    String? session,
  });

  Future<List<RepeatAbsentStudentDetail>> getRepeatAbsentStudents({
    required DateTime from,
    required DateTime to,
    String? session,
  });

  Future<List<ClassAttendanceRateDetail>> getClassAttendanceRates({
    required DateTime from,
    required DateTime to,
    String? session,
  });

  Future<List<LateAndRecessStudentDetail>> getLateAndRecessRecords({
    required DateTime from,
    required DateTime to,
    String? session,
  });

  Future<List<LeaveRecordDetail>> getLeaveRecords({
    required DateTime from,
    required DateTime to,
    String? session,
    String? status,
  });
}
