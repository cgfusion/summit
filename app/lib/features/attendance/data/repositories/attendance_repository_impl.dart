import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../student/domain/entities/student.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_log.dart';
import '../../domain/entities/register_qr_result.dart';
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

  @override
  Future<RegisterQrResult> registerToken({
    required String studentId,
    required String token,
    String? printedClassSnapshot,
  }) async {
    final existingOwner = await _findActiveTokenOwner(token);
    if (existingOwner != null) {
      if (existingOwner['student_id'] == studentId) {
        return const RegisterQrSuccess();
      }
      return RegisterQrTokenTaken(existingOwner['full_name'] as String);
    }

    final studentAlreadyHasToken = await _client
        .from('qr_tokens')
        .select('id')
        .eq('student_id', studentId)
        .eq('status', 'active')
        .maybeSingle();
    if (studentAlreadyHasToken != null) {
      return const RegisterQrStudentHasToken();
    }

    await _client.from('qr_tokens').insert({
      'student_id': studentId,
      'token': token,
      'printed_class_snapshot': ?printedClassSnapshot,
    });
    return const RegisterQrSuccess();
  }

  @override
  Future<RegisterQrResult> reissueToken({
    required String studentId,
    required String token,
    String? printedClassSnapshot,
  }) async {
    final existingOwner = await _findActiveTokenOwner(token);
    if (existingOwner != null && existingOwner['student_id'] != studentId) {
      return RegisterQrTokenTaken(existingOwner['full_name'] as String);
    }

    await _client
        .from('qr_tokens')
        .update({'status': 'revoked', 'revoked_at': DateTime.now().toIso8601String()})
        .eq('student_id', studentId)
        .eq('status', 'active');

    await _client.from('qr_tokens').insert({
      'student_id': studentId,
      'token': token,
      'printed_class_snapshot': ?printedClassSnapshot,
    });
    return const RegisterQrSuccess();
  }

  Future<Map<String, dynamic>?> _findActiveTokenOwner(String token) async {
    final row = await _client
        .from('qr_tokens')
        .select('student_id, students!inner(full_name)')
        .eq('token', token)
        .eq('status', 'active')
        .maybeSingle();
    if (row == null) return null;
    return {
      'student_id': row['student_id'],
      'full_name': (row['students'] as Map<String, dynamic>)['full_name'],
    };
  }

  String _dateOnly(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }
}
