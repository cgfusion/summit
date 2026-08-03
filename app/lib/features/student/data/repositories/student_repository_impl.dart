import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/student.dart';
import '../../domain/repositories/student_repository.dart';

class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _selectWithClass = 'id, student_id, full_name, ic_number, ic_type, date_of_birth, '
      'gender, study_status, enrolled_at, class_joined_at, class_id, classes(name)';

  @override
  Future<List<Student>> getStudents({String? classId, String? searchQuery}) async {
    var query = _client.from('students').select(_selectWithClass);

    if (classId != null) {
      query = query.eq('class_id', classId);
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
}
