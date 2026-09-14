import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/counseling_record.dart';
import '../../domain/entities/discipline_record.dart';
import '../../domain/entities/safe_questionnaire.dart';
import '../../domain/entities/school_announcement.dart';
import '../../domain/entities/sudut_info_post.dart';
import '../../domain/repositories/discipline_counseling_repository.dart';

class DisciplineCounselingRepositoryImpl implements DisciplineCounselingRepository {
  DisciplineCounselingRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<DisciplineRecord>> getDisciplineRecords({
    String? searchQuery,
    String? statusFilter,
    String? studentId,
  }) async {
    var query = _client.from('discipline_records').select('''
          id,
          student_id,
          reporter_id,
          incident_date,
          category,
          severity,
          action_taken,
          status,
          description,
          created_at,
          students!inner (
            id,
            full_name,
            class_id,
            classes!inner (
              name
            )
          ),
          profiles!inner (
            full_name
          )
        ''');

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    }

    final rows = await query.order('incident_date', ascending: false).order('created_at', ascending: false);

    final list = (rows as List).map((row) => DisciplineRecord.fromMap(row as Map<String, dynamic>)).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      return list
          .where((r) =>
              r.studentName.toLowerCase().contains(q) ||
              r.className.toLowerCase().contains(q) ||
              r.category.toLowerCase().contains(q) ||
              r.actionTaken.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Future<void> addDisciplineRecord({
    required String studentId,
    required String reporterId,
    required DateTime incidentDate,
    required String category,
    required String severity,
    required String actionTaken,
    required String status,
    String? description,
  }) async {
    await _client.from('discipline_records').insert({
      'student_id': studentId,
      'reporter_id': reporterId,
      'incident_date': formatDateOnly(incidentDate),
      'category': category,
      'severity': severity,
      'action_taken': actionTaken,
      'status': status,
      'description': description,
    });
  }

  @override
  Future<List<CounselingRecord>> getCounselingRecords({
    String? searchQuery,
    String? statusFilter,
    String? studentId,
  }) async {
    var query = _client.from('counseling_records').select('''
          id,
          student_id,
          counselor_id,
          discipline_record_id,
          session_date,
          session_type,
          focus_area,
          outcome_notes,
          follow_up_status,
          created_at,
          students!inner (
            id,
            full_name,
            class_id,
            classes!inner (
              name
            )
          ),
          profiles!inner (
            full_name
          )
        ''');

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('follow_up_status', statusFilter);
    }

    final rows = await query.order('session_date', ascending: false).order('created_at', ascending: false);

    final list = (rows as List).map((row) => CounselingRecord.fromMap(row as Map<String, dynamic>)).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      return list
          .where((r) =>
              r.studentName.toLowerCase().contains(q) ||
              r.className.toLowerCase().contains(q) ||
              r.focusArea.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Future<void> addCounselingRecord({
    required String studentId,
    required String counselorId,
    String? disciplineRecordId,
    required DateTime sessionDate,
    required String sessionType,
    required String focusArea,
    String? outcomeNotes,
    required String followUpStatus,
  }) async {
    await _client.from('counseling_records').insert({
      'student_id': studentId,
      'counselor_id': counselorId,
      'discipline_record_id': disciplineRecordId,
      'session_date': formatDateOnly(sessionDate),
      'session_type': sessionType,
      'focus_area': focusArea,
      'outcome_notes': outcomeNotes,
      'follow_up_status': followUpStatus,
    });
  }

  @override
  Future<Map<String, dynamic>> getStudentDisciplineSummary(String studentId) async {
    final result = await _client.rpc('fn_student_discipline_summary', params: {'p_student_id': studentId});
    return (result as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<List<SchoolAnnouncement>> getSchoolAnnouncements({
    String? category,
    bool onlyPublished = false,
  }) async {
    var query = _client.from('school_announcements').select('''
          id,
          author_id,
          category,
          title,
          content,
          target_student_id,
          is_published,
          created_at,
          profiles (
            full_name
          ),
          students (
            full_name
          )
        ''');

    if (onlyPublished) {
      query = query.eq('is_published', true);
    }

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final rows = await query.order('created_at', ascending: false);
    return (rows as List).map((r) => SchoolAnnouncement.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> createSchoolAnnouncement({
    required String category,
    required String title,
    required String content,
    String? authorId,
    String? targetStudentId,
  }) async {
    await _client.from('school_announcements').insert({
      'category': category,
      'title': title,
      'content': content,
      'author_id': authorId,
      'target_student_id': targetStudentId,
      'is_published': true,
    });
  }

  @override
  Future<void> updateSchoolAnnouncement({
    required String id,
    required String title,
    required String content,
    String? targetStudentId,
    bool? isPublished,
  }) async {
    final updateData = <String, dynamic>{
      'title': title,
      'content': content,
      'target_student_id': targetStudentId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (isPublished != null) {
      updateData['is_published'] = isPublished;
    }
    await _client.from('school_announcements').update(updateData).eq('id', id);
  }

  @override
  Future<void> toggleAnnouncementPublishedStatus({
    required String id,
    required bool isPublished,
  }) async {
    await _client.from('school_announcements').update({
      'is_published': isPublished,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteSchoolAnnouncement(String id) async {
    await _client.from('school_announcements').delete().eq('id', id);
  }

  // Sudut Info Implementation
  @override
  Future<List<SudutInfoPost>> getSudutInfoPosts({
    String? category,
    String? audience,
    bool onlyActive = false,
  }) async {
    var query = _client.from('sudut_info_posts').select('''
          id,
          author_id,
          category,
          audience,
          title,
          content,
          image_url,
          managed_by,
          is_published,
          valid_from,
          valid_until,
          created_at,
          profiles (
            full_name
          )
        ''');

    if (onlyActive) {
      final nowStr = DateTime.now().toUtc().toIso8601String();
      query = query
          .eq('is_published', true)
          .lte('valid_from', nowStr)
          .or('valid_until.is.null,valid_until.gte.$nowStr');
    }

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    if (audience != null && audience.isNotEmpty) {
      // A post targeted at "kedua_dua" (both) should show up for either
      // audience-specific query, in addition to an exact audience match.
      query = query.or('audience.eq.$audience,audience.eq.kedua_dua');
    }

    final rows = await query.order('created_at', ascending: false);
    return (rows as List).map((r) => SudutInfoPost.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> createSudutInfoPost({
    required String category,
    required String audience,
    required String title,
    required String content,
    String? imageUrl,
    String? managedBy,
    String? authorId,
    required DateTime validFrom,
    DateTime? validUntil,
  }) async {
    await _client.from('sudut_info_posts').insert({
      'category': category,
      'audience': audience,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'managed_by': managedBy ?? 'Unit Disiplin & Kaunseling',
      'author_id': authorId,
      'is_published': true,
      'valid_from': validFrom.toUtc().toIso8601String(),
      'valid_until': validUntil?.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> updateSudutInfoPost({
    required String id,
    required String category,
    required String audience,
    required String title,
    required String content,
    String? imageUrl,
    String? managedBy,
    required DateTime validFrom,
    DateTime? validUntil,
    bool? isPublished,
  }) async {
    final updateData = <String, dynamic>{
      'category': category,
      'audience': audience,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'managed_by': managedBy ?? 'Unit Disiplin & Kaunseling',
      'valid_from': validFrom.toUtc().toIso8601String(),
      'valid_until': validUntil?.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (isPublished != null) {
      updateData['is_published'] = isPublished;
    }
    await _client.from('sudut_info_posts').update(updateData).eq('id', id);
  }

  @override
  Future<void> toggleSudutInfoPublishStatus({
    required String id,
    required bool isPublished,
  }) async {
    await _client.from('sudut_info_posts').update({
      'is_published': isPublished,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteSudutInfoPost(String id) async {
    await _client.from('sudut_info_posts').delete().eq('id', id);
  }

  @override
  Future<void> submitSafeQuestionnaire({required String qrToken, required List<int> items}) async {
    assert(items.length == 12, 'SAFE questionnaire expects exactly 12 item scores');
    await _client.rpc('fn_submit_safe_questionnaire', params: {
      'p_qr_token': qrToken,
      'p_item_01': items[0],
      'p_item_02': items[1],
      'p_item_03': items[2],
      'p_item_04': items[3],
      'p_item_05': items[4],
      'p_item_06': items[5],
      'p_item_07': items[6],
      'p_item_08': items[7],
      'p_item_09': items[8],
      'p_item_10': items[9],
      'p_item_11': items[10],
      'p_item_12': items[11],
    });
  }

  @override
  Future<SafeQuestionnaireResult?> getMySafeQuestionnaire(String qrToken) async {
    final result = await _client.rpc('fn_get_my_safe_questionnaire', params: {'p_qr_token': qrToken});
    if (result == null) return null;
    return SafeQuestionnaireResult.fromMap(result as Map<String, dynamic>);
  }

  @override
  Future<SafeQuestionnaireSummary> getSafeQuestionnaireSummary() async {
    final result = await _client.rpc('fn_safe_questionnaire_summary');
    return SafeQuestionnaireSummary.fromMap(result as Map<String, dynamic>);
  }

  @override
  Future<List<SafeQuestionnaireResponseRow>> getAllSafeQuestionnaireResponses() async {
    final rows = await _client
        .from('safe_questionnaire_responses')
        .select('''
          student_id, item_01, item_02, item_03, item_04, item_05, item_06,
          item_07, item_08, item_09, item_10, item_11, item_12, submitted_at,
          students ( full_name, classes ( name ) )
        ''')
        .order('submitted_at', ascending: false);
    return (rows as List).map((r) => SafeQuestionnaireResponseRow.fromMap(r as Map<String, dynamic>)).toList();
  }
}
