import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/student_portal_data.dart';
import '../../domain/entities/student_voice_submission.dart';
import '../../domain/repositories/student_portal_repository.dart';

class StudentPortalRepositoryImpl implements StudentPortalRepository {
  StudentPortalRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<StudentPortalData?> getStudentPortalDataByQr(String qrToken) async {
    final result = await _client.rpc('fn_student_portal_data_by_qr', params: {'p_qr_token': qrToken.trim()});
    if (result == null) return null;
    return StudentPortalData.fromMap(result as Map<String, dynamic>);
  }

  @override
  Future<void> submitStudentVoice({
    required String? studentId,
    required String category,
    required bool isAnonymous,
    required String subject,
    required String message,
  }) async {
    await _client.from('student_voice_submissions').insert({
      'student_id': isAnonymous ? null : studentId,
      'category': category,
      'is_anonymous': isAnonymous,
      'subject': subject,
      'message': message,
      'status': 'baru',
    });
  }

  @override
  Future<List<StudentVoiceSubmission>> getAllVoiceSubmissions({
    String? statusFilter,
    String? categoryFilter,
  }) async {
    var query = _client.from('student_voice_submissions').select('''
          id,
          student_id,
          category,
          is_anonymous,
          subject,
          message,
          status,
          response_notes,
          responded_by,
          created_at,
          students (
            full_name,
            classes (
              name
            )
          ),
          profiles (
            full_name
          )
        ''');

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    }
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      query = query.eq('category', categoryFilter);
    }

    final rows = await query.order('created_at', ascending: false);

    return (rows as List).map((row) => StudentVoiceSubmission.fromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> respondToVoiceSubmission({
    required String submissionId,
    required String status,
    required String responseNotes,
    required String responderId,
  }) async {
    await _client.from('student_voice_submissions').update({
      'status': status,
      'response_notes': responseNotes,
      'responded_by': responderId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', submissionId);
  }
}
