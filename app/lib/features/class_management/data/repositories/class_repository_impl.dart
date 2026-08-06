import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/school_class.dart';
import '../../domain/repositories/class_repository.dart';

class ClassRepositoryImpl implements ClassRepository {
  ClassRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _select = 'id, name, form_level, session, homeroom_teacher_name, homeroom_teacher_id';

  @override
  Future<List<SchoolClass>> getClasses() async {
    final rows = await _client.from('classes').select(_select).order('form_level').order('name');
    return rows.map((row) => SchoolClass.fromMap(row)).toList();
  }

  @override
  Future<SchoolClass?> getById(String id) async {
    final row = await _client.from('classes').select(_select).eq('id', id).maybeSingle();
    return row == null ? null : SchoolClass.fromMap(row);
  }
}
