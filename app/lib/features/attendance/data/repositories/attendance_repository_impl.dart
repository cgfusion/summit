import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../student/domain/entities/student.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_log.dart';
import '../../domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _studentSelectWithClass = 'id, student_id, full_name, ic_number, ic_type, date_of_birth, '
      'gender, study_status, enrolled_at, class_joined_at, class_id, classes(name)';

  @override
  Future<Student?> resolveQrToken(String token) async {
    final row = await _client
        .from('qr_tokens')
        .select('status, students!inner($_studentSelectWithClass)')
        .eq('token', token)
        .eq('status', 'active')
        .maybeSingle();

    if (row == null) return null;
    return Student.fromMap(row['students'] as Map<String, dynamic>);
  }

  @override
  Future<AttendanceLog> recordScan({required String studentId, String? deviceLabel}) async {
    final userId = _client.auth.currentUser?.id;
    final row = await _client
        .from('attendance_logs')
        .insert({
          'student_id': studentId,
          'scanned_by': ?userId,
          'device_label': ?deviceLabel,
        })
        .select()
        .single();
    return AttendanceLog.fromMap(row);
  }

  @override
  Future<List<AttendanceDay>> getAttendanceForDate({required DateTime date, String? classId}) async {
    final schoolDate = _dateOnly(date);
    var query = _client
        .from('attendance_days')
        .select('id, student_id, school_date, status, source, first_scan_at, students!inner(full_name, class_id)')
        .eq('school_date', schoolDate);

    if (classId != null) {
      query = query.eq('students.class_id', classId);
    }

    final rows = await query.order('first_scan_at');
    return rows.map((row) => AttendanceDay.fromMap(row)).toList();
  }

  @override
  Future<AttendanceDay?> getAttendanceForStudentOnDate({required String studentId, required DateTime date}) async {
    final schoolDate = _dateOnly(date);
    final row = await _client
        .from('attendance_days')
        .select('id, student_id, school_date, status, source, first_scan_at, students!inner(full_name, class_id)')
        .eq('student_id', studentId)
        .eq('school_date', schoolDate)
        .maybeSingle();
    return row == null ? null : AttendanceDay.fromMap(row);
  }

  String _dateOnly(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }
}
