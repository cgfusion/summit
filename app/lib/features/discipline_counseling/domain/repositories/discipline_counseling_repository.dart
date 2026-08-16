import '../entities/counseling_record.dart';
import '../entities/discipline_record.dart';
import '../entities/school_announcement.dart';

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

  Future<List<SchoolAnnouncement>> getSchoolAnnouncements({String? category});

  Future<void> createSchoolAnnouncement({
    required String category, // 'disiplin' or 'kaunseling'
    required String title,
    required String content,
    String? authorId,
    String? targetStudentId,
  });
}
