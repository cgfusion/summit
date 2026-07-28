import 'attendance_status.dart';

class AttendanceDay {
  const AttendanceDay({
    required this.id,
    required this.studentId,
    required this.schoolDate,
    required this.status,
    required this.source,
    this.firstScanAt,
    this.studentName,
  });

  final String id;
  final String studentId;
  final DateTime schoolDate;
  final AttendanceStatus status;
  final String source;
  final DateTime? firstScanAt;
  final String? studentName;

  factory AttendanceDay.fromMap(Map<String, dynamic> map) {
    final studentRow = map['students'] as Map<String, dynamic>?;
    return AttendanceDay(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      schoolDate: DateTime.parse(map['school_date'] as String),
      status: AttendanceStatus.fromDb(map['status'] as String),
      source: map['source'] as String,
      firstScanAt: map['first_scan_at'] == null ? null : DateTime.parse(map['first_scan_at'] as String),
      studentName: studentRow?['full_name'] as String?,
    );
  }
}
