import '../entities/student_portal_data.dart';
import '../entities/student_voice_submission.dart';

abstract interface class StudentPortalRepository {
  Future<StudentPortalData?> getStudentPortalDataByQr(String qrToken);

  Future<void> submitStudentVoice({
    required String? studentId,
    required String category,
    required bool isAnonymous,
    required String subject,
    required String message,
  });

  Future<List<StudentVoiceSubmission>> getAllVoiceSubmissions({
    String? statusFilter,
    String? categoryFilter,
  });

  Future<void> respondToVoiceSubmission({
    required String submissionId,
    required String status,
    required String responseNotes,
    required String responderId,
  });
}
