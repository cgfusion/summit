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
  }) async {
    final rows = await _client
        .from('attendance_days')
        .select(
            'student_id, status, students!inner(id, full_name, ic_number, class_id, enrollment_status, classes!inner(id, name, session))')
        .gte('school_date', formatDateOnly(from))
        .lte('school_date', formatDateOnly(to))
        .eq('students.enrollment_status', 'active');

    final map = <String, Map<String, dynamic>>{};
    for (final row in (rows as List)) {
      final student = row['students'] as Map<String, dynamic>;
      final cls = student['classes'] as Map<String, dynamic>;
      final sSession = cls['session'] as String?;
      if (session != null && sSession != session) continue;

      final studentId = student['id'] as String;
      final status = row['status'] as String;

      final entry = map.putIfAbsent(
        studentId,
        () => {
          'studentId': studentId,
          'fullName': student['full_name'] as String,
          'classId': student['class_id'] as String,
          'className': cls['name'] as String,
          'session': sSession ?? '',
          'icNumber': student['ic_number'] as String?,
          'absentCount': 0,
          'presentCount': 0,
          'totalDays': 0,
        },
      );

      entry['totalDays'] = (entry['totalDays'] as int) + 1;
      if (status == 'tidak_hadir') {
        entry['absentCount'] = (entry['absentCount'] as int) + 1;
      } else if (status == 'hadir' || status == 'lewat') {
        entry['presentCount'] = (entry['presentCount'] as int) + 1;
      }
    }

    final results = map.values
        .where((e) => (e['absentCount'] as int) >= 2)
        .map((e) => RepeatAbsentStudentDetail(
              studentId: e['studentId'] as String,
              fullName: e['fullName'] as String,
              classId: e['classId'] as String,
              className: e['className'] as String,
              session: e['session'] as String,
              absentCount: e['absentCount'] as int,
              presentCount: e['presentCount'] as int,
              totalDays: e['totalDays'] as int,
              icNumber: e['icNumber'] as String?,
            ))
        .toList()
      ..sort((a, b) => b.absentCount.compareTo(a.absentCount));

    return results;
  }

  @override
  Future<List<ClassAttendanceRateDetail>> getClassAttendanceRates({
    required DateTime from,
    required DateTime to,
    String? session,
  }) async {
    var classQuery = _client.from('classes').select('id, name, form_level, session, profiles(full_name)');
    if (session != null) {
      classQuery = classQuery.eq('session', session);
    }
    final classRows = await classQuery;

    final attRows = await _client
        .from('attendance_days')
        .select('status, students!inner(class_id, enrollment_status)')
        .gte('school_date', formatDateOnly(from))
        .lte('school_date', formatDateOnly(to))
        .eq('students.enrollment_status', 'active');

    final stats = <String, Map<String, int>>{};
    for (final r in (attRows as List)) {
      final s = r['students'] as Map<String, dynamic>;
      final cId = s['class_id'] as String?;
      if (cId == null) continue;
      final st = stats.putIfAbsent(cId, () => {'present': 0, 'absent': 0, 'total': 0});
      st['total'] = st['total']! + 1;
      final status = r['status'] as String;
      if (status == 'hadir' || status == 'lewat') {
        st['present'] = st['present']! + 1;
      } else if (status == 'tidak_hadir') {
        st['absent'] = st['absent']! + 1;
      }
    }

    final list = (classRows as List).map((c) {
      final cId = c['id'] as String;
      final prof = c['profiles'] as Map<String, dynamic>?;
      final s = stats[cId] ?? {'present': 0, 'absent': 0, 'total': 0};
      final total = s['total']!;
      final present = s['present']!;
      final rate = total == 0 ? 0.0 : (present / total * 100);
      return ClassAttendanceRateDetail(
        classId: cId,
        className: c['name'] as String,
        formLevel: c['form_level'] as int,
        session: c['session'] as String,
        homeroomTeacherName: prof?['full_name'] as String?,
        totalRecords: total,
        presentCount: present,
        absentCount: s['absent']!,
        attendanceRate: rate,
      );
    }).toList()
      ..sort((a, b) => a.attendanceRate.compareTo(b.attendanceRate));

    return list;
  }

  @override
  Future<List<LateAndRecessStudentDetail>> getLateAndRecessRecords({
    required DateTime from,
    required DateTime to,
    String? session,
  }) async {
    final lateRows = await _client
        .from('attendance_days')
        .select('student_id, students!inner(id, full_name, class_id, enrollment_status, classes!inner(name, session))')
        .gte('school_date', formatDateOnly(from))
        .lte('school_date', formatDateOnly(to))
        .eq('status', 'lewat')
        .eq('students.enrollment_status', 'active');

    final recessRows = await _client
        .from('attendance_day_exceptions')
        .select('student_id, students!inner(id, full_name, class_id, enrollment_status, classes!inner(name, session))')
        .gte('school_date', formatDateOnly(from))
        .lte('school_date', formatDateOnly(to))
        .eq('missed_recess_return', true)
        .eq('students.enrollment_status', 'active');

    final map = <String, Map<String, dynamic>>{};

    void process(List rows, bool isLate) {
      for (final row in rows) {
        final student = row['students'] as Map<String, dynamic>;
        final cls = student['classes'] as Map<String, dynamic>;
        final sSession = cls['session'] as String?;
        if (session != null && sSession != session) continue;
        final studentId = student['id'] as String;

        final entry = map.putIfAbsent(studentId, () => {
              'studentId': studentId,
              'fullName': student['full_name'] as String,
              'classId': student['class_id'] as String,
              'className': cls['name'] as String,
              'session': sSession ?? '',
              'lateCount': 0,
              'missedRecessCount': 0,
            });

        if (isLate) {
          entry['lateCount'] = (entry['lateCount'] as int) + 1;
        } else {
          entry['missedRecessCount'] = (entry['missedRecessCount'] as int) + 1;
        }
      }
    }

    process(lateRows as List, true);
    process(recessRows as List, false);

    final results = map.values
        .map((e) => LateAndRecessStudentDetail(
              studentId: e['studentId'] as String,
              fullName: e['fullName'] as String,
              classId: e['classId'] as String,
              className: e['className'] as String,
              session: e['session'] as String,
              lateCount: e['lateCount'] as int,
              missedRecessCount: e['missedRecessCount'] as int,
            ))
        .toList()
      ..sort((a, b) => (b.lateCount + b.missedRecessCount).compareTo(a.lateCount + a.missedRecessCount));

    return results;
  }

  @override
  Future<List<LeaveRecordDetail>> getLeaveRecords({
    required DateTime from,
    required DateTime to,
    String? session,
    String? status,
  }) async {
    var query = _client
        .from('attendance_days')
        .select('id, student_id, school_date, status, students!inner(id, full_name, class_id, enrollment_status, classes!inner(name, session))')
        .gte('school_date', formatDateOnly(from))
        .lte('school_date', formatDateOnly(to))
        .inFilter('status', status != null ? [status] : ['tidak_hadir', 'cuti_sakit', 'urusan_rasmi'])
        .eq('students.enrollment_status', 'active');

    final rows = await query;
    final list = <LeaveRecordDetail>[];

    for (final row in (rows as List)) {
      final student = row['students'] as Map<String, dynamic>;
      final cls = student['classes'] as Map<String, dynamic>;
      final sSession = cls['session'] as String?;
      if (session != null && sSession != session) continue;

      list.add(LeaveRecordDetail(
        id: row['id'] as String,
        studentId: student['id'] as String,
        fullName: student['full_name'] as String,
        classId: student['class_id'] as String,
        className: cls['name'] as String,
        session: sSession ?? '',
        schoolDate: DateTime.parse(row['school_date'] as String),
        status: row['status'] as String,
      ));
    }

    list.sort((a, b) => b.schoolDate.compareTo(a.schoolDate));
    return list;
  }
}
