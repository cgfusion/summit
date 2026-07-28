import '../../../student/domain/entities/student.dart';
import '../entities/attendance_day.dart';
import '../entities/attendance_log.dart';

abstract interface class AttendanceRepository {
  /// Resolves an active QR token to the student it belongs to, or null if
  /// the token is unknown/revoked.
  Future<Student?> resolveQrToken(String token);

  /// Records a raw scan event. The `handle_attendance_scan` DB trigger
  /// derives/updates the day's canonical [AttendanceDay] status.
  Future<AttendanceLog> recordScan({required String studentId, String? deviceLabel});

  Future<List<AttendanceDay>> getAttendanceForDate({required DateTime date, String? classId});

  Future<AttendanceDay?> getAttendanceForStudentOnDate({required String studentId, required DateTime date});
}
