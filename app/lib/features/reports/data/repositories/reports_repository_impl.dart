import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/kpi_trend_week.dart';
import '../../domain/entities/report_drill_down_entities.dart';
import '../../domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<KpiTrendWeek>> getWeeklyKpiTrend({
    required DateTime from,
    required DateTime to,
    String? session,
  }) async {
    final rows = await _client.rpc('fn_weekly_kpi_trend', params: {
      'p_from': formatDateOnly(from),
      'p_to': formatDateOnly(to),
      'p_session': session,
    });
    return (rows as List).map((row) => KpiTrendWeek.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<RepeatAbsentStudentDetail>> getRepeatAbsentStudents({
    required DateTime from,
    required DateTime to,
    String? session,
    int minAbsent = 2,
  }) async {
    final rows = await _client.rpc('fn_repeat_absent_students', params: {
      'p_from': formatDateOnly(from),
      'p_to': formatDateOnly(to),
      'p_session': session,
      'p_min_absent': minAbsent,
    });

    return (rows as List)
        .map((row) => RepeatAbsentStudentDetail(
              studentId: row['student_id'] as String,
              fullName: row['full_name'] as String,
              classId: row['class_id'] as String,
              className: row['class_name'] as String,
              session: row['session'] as String,
              absentCount: (row['absent_count'] as num).toInt(),
              presentCount: (row['present_count'] as num).toInt(),
              totalDays: (row['total_days'] as num).toInt(),
              icNumber: row['ic_number'] as String?,
            ))
        .toList();
  }

  @override
  Future<List<ClassAttendanceRateDetail>> getClassAttendanceRates({
    required DateTime from,
    required DateTime to,
    String? session,
  }) async {
    final rows = await _client.rpc('fn_class_attendance_rates', params: {
      'p_from': formatDateOnly(from),
      'p_to': formatDateOnly(to),
      'p_session': session,
    });

    return (rows as List)
        .map((row) => ClassAttendanceRateDetail(
              classId: row['class_id'] as String,
              className: row['class_name'] as String,
              formLevel: (row['form_level'] as num).toInt(),
              session: row['session'] as String,
              homeroomTeacherName: row['homeroom_teacher_name'] as String?,
              totalRecords: (row['total_records'] as num).toInt(),
              presentCount: (row['present_count'] as num).toInt(),
              absentCount: (row['absent_count'] as num).toInt(),
              attendanceRate: (row['attendance_rate'] as num).toDouble(),
            ))
        .toList();
  }

  @override
  Future<List<LateAndRecessStudentDetail>> getLateAndRecessRecords({
    required DateTime from,
    required DateTime to,
    String? session,
  }) async {
    final rows = await _client.rpc('fn_late_and_recess_students', params: {
      'p_from': formatDateOnly(from),
      'p_to': formatDateOnly(to),
      'p_session': session,
    });

    return (rows as List)
        .map((row) => LateAndRecessStudentDetail(
              studentId: row['student_id'] as String,
              fullName: row['full_name'] as String,
              classId: row['class_id'] as String,
              className: row['class_name'] as String,
              session: row['session'] as String,
              lateCount: (row['late_count'] as num).toInt(),
              missedRecessCount: (row['missed_recess_count'] as num).toInt(),
            ))
        .toList();
  }

  @override
  Future<List<LeaveRecordDetail>> getLeaveRecords({
    required DateTime from,
    required DateTime to,
    String? session,
    String? status,
  }) async {
    final rows = await _client.rpc('fn_leave_type_records', params: {
      'p_from': formatDateOnly(from),
      'p_to': formatDateOnly(to),
      'p_session': session,
      'p_status': status,
    });

    return (rows as List)
        .map((row) => LeaveRecordDetail(
              id: row['id'] as String,
              studentId: row['student_id'] as String,
              fullName: row['full_name'] as String,
              classId: row['class_id'] as String,
              className: row['class_name'] as String,
              session: row['session'] as String,
              schoolDate: DateTime.parse(row['school_date'] as String),
              status: row['status'] as String,
            ))
        .toList();
  }
}
