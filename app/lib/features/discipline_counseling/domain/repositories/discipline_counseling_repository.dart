import '../entities/counseling_record.dart';
import '../entities/discipline_record.dart';
import '../entities/school_announcement.dart';
import '../entities/sudut_info_post.dart';

abstract interface class DisciplineCounselingRepository {
  Future<List<DisciplineRecord>> getDisciplineRecords({
    String? searchQuery,
    String? statusFilter,
    String? studentId,
  });

  Future<void> addDisciplineRecord({
    required String studentId,
    required String reporterId,
    required DateTime incidentDate,
    required String category,
    required String severity,
    required String actionTaken,
    required String status,
    String? description,
  });

  Future<List<CounselingRecord>> getCounselingRecords({
    String? searchQuery,
    String? statusFilter,
    String? studentId,
  });

  Future<void> addCounselingRecord({
    required String studentId,
    required String counselorId,
    String? disciplineRecordId,
    required DateTime sessionDate,
    required String sessionType,
    required String focusArea,
    String? outcomeNotes,
    required String followUpStatus,
  });

  Future<Map<String, dynamic>> getStudentDisciplineSummary(String studentId);

  Future<List<SchoolAnnouncement>> getSchoolAnnouncements({
    String? category,
    bool onlyPublished = false,
  });

  Future<void> createSchoolAnnouncement({
    required String category, // 'disiplin' or 'kaunseling'
    required String title,
    required String content,
    String? authorId,
    String? targetStudentId,
  });

  Future<void> updateSchoolAnnouncement({
    required String id,
    required String title,
    required String content,
    String? targetStudentId,
    bool? isPublished,
  });

  Future<void> toggleAnnouncementPublishedStatus({
    required String id,
    required bool isPublished,
  });

  Future<void> deleteSchoolAnnouncement(String id);

  // Sudut Info Management
  Future<List<SudutInfoPost>> getSudutInfoPosts({
    String? category,
    bool onlyActive = false,
  });

  Future<void> createSudutInfoPost({
    required String category,
    required String title,
    required String content,
    String? imageUrl,
    String? managedBy,
    String? authorId,
    required DateTime validFrom,
    DateTime? validUntil,
  });

  Future<void> updateSudutInfoPost({
    required String id,
    required String category,
    required String title,
    required String content,
    String? imageUrl,
    String? managedBy,
    required DateTime validFrom,
    DateTime? validUntil,
    bool? isPublished,
  });

  Future<void> toggleSudutInfoPublishStatus({
    required String id,
    required bool isPublished,
  });

  Future<void> deleteSudutInfoPost(String id);
}
