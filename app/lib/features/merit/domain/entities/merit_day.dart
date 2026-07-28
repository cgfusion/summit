import '../../../attendance/domain/entities/attendance_status.dart';

/// One student's 4-point merit breakdown for a single school day.
class MeritDay {
  const MeritDay({
    required this.studentId,
    required this.studentName,
    required this.schoolDate,
    required this.classId,
    required this.attendanceStatus,
    required this.pointHadir,
    required this.pointTepatMasa,
    required this.pointKembaliRehat,
    required this.pointKekalSesi,
    required this.bonus,
    required this.totalPoints,
  });

  final String studentId;
  final String studentName;
  final DateTime schoolDate;
  final String? classId;
  final AttendanceStatus attendanceStatus;
  final int pointHadir;
  final int pointTepatMasa;
  final int pointKembaliRehat;
  final int pointKekalSesi;
  final int bonus;
  final int totalPoints;

  factory MeritDay.fromMap(Map<String, dynamic> map) {
    return MeritDay(
      studentId: map['student_id'] as String,
      studentName: map['full_name'] as String,
      schoolDate: DateTime.parse(map['school_date'] as String),
      classId: map['class_id'] as String?,
      attendanceStatus: AttendanceStatus.fromDb(map['attendance_status'] as String),
      pointHadir: map['point_hadir'] as int,
      pointTepatMasa: map['point_tepat_masa'] as int,
      pointKembaliRehat: map['point_kembali_rehat'] as int,
      pointKekalSesi: map['point_kekal_sesi'] as int,
      bonus: map['bonus'] as int,
      totalPoints: map['total_points'] as int,
    );
  }
}
