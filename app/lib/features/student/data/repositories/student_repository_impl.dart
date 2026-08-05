import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/enrollment_status.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/student_guardian.dart';
import '../../domain/repositories/student_repository.dart';

class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _selectWithClass = 'id, student_id, full_name, ic_number, ic_type, date_of_birth, '
      'gender, study_status, enrolled_at, class_joined_at, class_id, classes(name), '
      'enrollment_status, enrollment_status_reason, enrollment_status_date';

  @override
  Future<List<Student>> getStudents({String? classId, String? searchQuery, bool activeOnly = true}) async {
    var query = _client.from('students').select(_selectWithClass);

    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (activeOnly) {
      query = query.eq('enrollment_status', 'active');
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('full_name.ilike.%$q%,ic_number.ilike.%$q%');
    }

    final rows = await query.order('full_name');
    return rows.map((row) => Student.fromMap(row)).toList();
  }

  @override
  Future<Student?> getByStudentId(int studentId) async {
    final row = await _client.from('students').select(_selectWithClass).eq('student_id', studentId).maybeSingle();
    return row == null ? null : Student.fromMap(row);
  }

  @override
  Future<Student?> getById(String id) async {
    final row = await _client.from('students').select(_selectWithClass).eq('id', id).maybeSingle();
    return row == null ? null : Student.fromMap(row);
  }

  @override
  Future<void> updateEnrollmentStatus({
    required String studentId,
    required EnrollmentStatus status,
    String? reason,
    required DateTime effectiveDate,
  }) async {
    await _client.rpc('fn_update_student_status', params: {
      'p_student_id': studentId,
      'p_status': status.dbValue,
      'p_reason': ?reason,
      'p_date': _dateOnly(effectiveDate),
    });
  }

  @override
  Future<List<StudentGuardian>> getGuardians(String studentId) async {
    final rows = await _client
        .from('student_guardians')
        .select()
        .eq('student_id', studentId)
        .order('is_primary', ascending: false)
        .order('full_name');
    return rows.map((row) => StudentGuardian.fromMap(row)).toList();
  }

  @override
  Future<void> addGuardian({
    required String studentId,
    required String fullName,
    String? relationship,
    String? icNumber,
    String? phone,
    String? email,
    bool isPrimary = false,
    bool isEmergencyContact = false,
    String? notes,
  }) async {
    await _client.from('student_guardians').insert({
      'student_id': studentId,
      'full_name': fullName,
      'relationship': ?relationship,
      'ic_number': ?icNumber,
      'phone': ?phone,
      'email': ?email,
      'is_primary': isPrimary,
      'is_emergency_contact': isEmergencyContact,
      'notes': ?notes,
    });
  }

  @override
  Future<void> updateGuardian({
    required String guardianId,
    required String fullName,
    String? relationship,
    String? icNumber,
    String? phone,
    String? email,
    bool isPrimary = false,
    bool isEmergencyContact = false,
    String? notes,
  }) async {
    await _client.from('student_guardians').update({
      'full_name': fullName,
      'relationship': relationship,
      'ic_number': icNumber,
      'phone': phone,
      'email': email,
      'is_primary': isPrimary,
      'is_emergency_contact': isEmergencyContact,
      'notes': notes,
    }).eq('id', guardianId);
  }

  @override
  Future<void> deleteGuardian(String guardianId) async {
    await _client.from('student_guardians').delete().eq('id', guardianId);
  }

  @override
  Future<String> regenerateGuardianToken(String guardianId) async {
    final result = await _client.rpc('fn_regenerate_guardian_token', params: {'p_guardian_id': guardianId});
    return result as String;
  }

  String _dateOnly(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }
}
