import '../entities/enrollment_status.dart';
import '../entities/student.dart';
import '../entities/student_guardian.dart';

abstract interface class StudentRepository {
  /// [activeOnly] defaults to true so every existing caller (attendance
  /// rosters, search) automatically excludes expelled/transferred/etc.
  /// students; pass false for the Students management screen, which needs
  /// to see everyone.
  Future<List<Student>> getStudents({String? classId, String? searchQuery, bool activeOnly = true});

  Future<Student?> getByStudentId(int studentId);

  Future<Student?> getById(String id);

  Future<void> updateEnrollmentStatus({
    required String studentId,
    required EnrollmentStatus status,
    String? reason,
    required DateTime effectiveDate,
  });

  Future<List<StudentGuardian>> getGuardians(String studentId);

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
  });

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
  });

  Future<void> deleteGuardian(String guardianId);
}
