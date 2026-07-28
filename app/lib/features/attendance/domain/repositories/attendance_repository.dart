import '../../../student/domain/entities/student.dart';
import '../entities/attendance_day.dart';
import '../entities/attendance_log.dart';
import '../entities/register_qr_result.dart';

abstract interface class AttendanceRepository {
  /// Resolves an active QR token to the student it belongs to, or null if
  /// the token is unknown/revoked.
  Future<Student?> resolveQrToken(String token);

  /// Records a raw scan event. The `handle_attendance_scan` DB trigger
  /// derives/updates the day's canonical [AttendanceDay] status.
  Future<AttendanceLog> recordScan({required String studentId, String? deviceLabel});

  Future<List<AttendanceDay>> getAttendanceForDate({required DateTime date, String? classId});

  Future<AttendanceDay?> getAttendanceForStudentOnDate({required String studentId, required DateTime date});

  /// Binds [token] to [studentId] as their active card. Fails safe (no
  /// write) if the token belongs to someone else, or if the student already
  /// has a different active token -- see [reissueToken] for that case.
  Future<RegisterQrResult> registerToken({
    required String studentId,
    required String token,
    String? printedClassSnapshot,
  });

  /// Revokes [studentId]'s current active token (if any) and registers
  /// [token] as their new one. Call after the caller has confirmed the
  /// replacement with the user (typically following a [RegisterQrStudentHasToken] result).
  Future<RegisterQrResult> reissueToken({
    required String studentId,
    required String token,
    String? printedClassSnapshot,
  });
}
