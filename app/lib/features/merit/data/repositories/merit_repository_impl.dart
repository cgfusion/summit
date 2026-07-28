import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/class_period_summary.dart';
import '../../domain/entities/merit_award.dart';
import '../../domain/entities/merit_day.dart';
import '../../domain/entities/student_period_summary.dart';
import '../../domain/repositories/merit_repository.dart';
import '../../domain/value_objects/date_range.dart';

class MeritRepositoryImpl implements MeritRepository {
  MeritRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<DateRange> getProgramPeriod() async {
    final row = await _client.from('attendance_settings').select('program_start_date, program_end_date').single();
    return (
      from: DateTime.parse(row['program_start_date'] as String),
      to: DateTime.parse(row['program_end_date'] as String),
    );
  }

  @override
  Future<List<MeritDay>> getDailyMerit({required DateTime date, String? classId}) async {
    var query = _client
        .from('merit_student_daily')
        .select('student_id, school_date, class_id, attendance_status, point_hadir, point_tepat_masa, '
            'point_kembali_rehat, point_kekal_sesi, bonus, total_points, full_name')
        .eq('school_date', _dateOnly(date));

    if (classId != null) {
      query = query.eq('class_id', classId);
    }

    final rows = await query.order('full_name');
    return rows.map((row) => MeritDay.fromMap(row)).toList();
  }

  @override
  Future<void> setException({
    required String studentId,
    required DateTime date,
    required bool missedRecessReturn,
    required bool leftEarly,
  }) async {
    final schoolDate = _dateOnly(date);
    if (!missedRecessReturn && !leftEarly) {
      await _client.from('attendance_day_exceptions').delete().eq('student_id', studentId).eq('school_date', schoolDate);
      return;
    }

    final userId = _client.auth.currentUser?.id;
    await _client.from('attendance_day_exceptions').upsert({
      'student_id': studentId,
      'school_date': schoolDate,
      'missed_recess_return': missedRecessReturn,
      'left_early': leftEarly,
      'noted_by': ?userId,
      'noted_at': DateTime.now().toIso8601String(),
    }, onConflict: 'student_id,school_date');
  }

  @override
  Future<void> addBonus({
    required String studentId,
    required DateTime date,
    required int points,
    String? reason,
  }) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('merit_bonus_points').insert({
      'student_id': studentId,
      'school_date': _dateOnly(date),
      'points': points,
      'reason': ?reason,
      'awarded_by': ?userId,
    });
  }

  @override
  Future<List<StudentPeriodSummary>> getStudentSummary({
    required DateTime from,
    required DateTime to,
    String? classId,
  }) async {
    final rows = await _client.rpc('fn_student_period_summary', params: {
      'p_from': _dateOnly(from),
      'p_to': _dateOnly(to),
      'p_class_id': classId,
    });
    return (rows as List).map((row) => StudentPeriodSummary.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ClassPeriodSummary>> getClassSummary({required DateTime from, required DateTime to}) async {
    final rows = await _client.rpc('fn_class_period_summary', params: {
      'p_from': _dateOnly(from),
      'p_to': _dateOnly(to),
    });
    return (rows as List).map((row) => ClassPeriodSummary.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> logAward({
    required MeritAwardCategory category,
    required String scopeType,
    String? studentId,
    String? classId,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? note,
  }) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('merit_awards').insert({
      'category': category.dbValue,
      'scope_type': scopeType,
      'student_id': ?studentId,
      'class_id': ?classId,
      'period_start': _dateOnly(periodStart),
      'period_end': _dateOnly(periodEnd),
      'awarded_by': ?userId,
      'note': ?note,
    });
  }

  @override
  Future<List<MeritAward>> getAwards({required DateTime periodStart, required DateTime periodEnd}) async {
    final rows = await _client
        .from('merit_awards')
        .select()
        .eq('period_start', _dateOnly(periodStart))
        .eq('period_end', _dateOnly(periodEnd))
        .order('awarded_at', ascending: false);
    return rows.map((row) => MeritAward.fromMap(row)).toList();
  }

  String _dateOnly(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }
}
