import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../student/domain/entities/enrollment_status.dart';

class ParentPortalAttendanceDay {
  const ParentPortalAttendanceDay({required this.date, required this.status});

  final DateTime date;
  final AttendanceStatus status;

  factory ParentPortalAttendanceDay.fromMap(Map<String, dynamic> map) {
    return ParentPortalAttendanceDay(
      date: DateTime.parse(map['date'] as String),
      status: AttendanceStatus.fromDb(map['status'] as String),
    );
  }
}

class ParentPortalData {
  const ParentPortalData({
    required this.studentFullName,
    required this.className,
    required this.enrollmentStatus,
    this.enrollmentStatusReason,
    this.enrollmentStatusDate,
    required this.attendanceRecent,
    required this.attendanceWeekPresent,
    required this.attendanceWeekTotal,
    required this.attendanceMonthPresent,
    required this.attendanceMonthTotal,
    required this.meritTotalPoints,
    required this.meritDaysRecorded,
    required this.meritMaxPointsPerDay,
  });

  final String studentFullName;
  final String? className;
  final EnrollmentStatus enrollmentStatus;
  final String? enrollmentStatusReason;
  final DateTime? enrollmentStatusDate;
  final List<ParentPortalAttendanceDay> attendanceRecent;
  final int attendanceWeekPresent;
  final int attendanceWeekTotal;
  final int attendanceMonthPresent;
  final int attendanceMonthTotal;
  final int meritTotalPoints;
  final int meritDaysRecorded;
  final int meritMaxPointsPerDay;

  int get meritMaxPoints => meritDaysRecorded * meritMaxPointsPerDay;

  double get attendanceWeekRate => attendanceWeekTotal == 0 ? 0 : attendanceWeekPresent / attendanceWeekTotal * 100;

  double get attendanceMonthRate =>
      attendanceMonthTotal == 0 ? 0 : attendanceMonthPresent / attendanceMonthTotal * 100;

  double get meritRate => meritMaxPoints == 0 ? 0 : meritTotalPoints / meritMaxPoints * 100;

  factory ParentPortalData.fromMap(Map<String, dynamic> map) {
    final student = map['student'] as Map<String, dynamic>;
    final attendanceWeek = map['attendance_week'] as Map<String, dynamic>;
    final attendanceMonth = map['attendance_month'] as Map<String, dynamic>;
    final meritMonth = map['merit_month'] as Map<String, dynamic>;
    final recent = (map['attendance_recent'] as List).cast<Map<String, dynamic>>();

    return ParentPortalData(
      studentFullName: student['full_name'] as String,
      className: student['class_name'] as String?,
      enrollmentStatus: EnrollmentStatus.fromDb(student['enrollment_status'] as String),
      enrollmentStatusReason: student['enrollment_status_reason'] as String?,
      enrollmentStatusDate: student['enrollment_status_date'] == null
          ? null
          : DateTime.parse(student['enrollment_status_date'] as String),
      attendanceRecent: recent.map(ParentPortalAttendanceDay.fromMap).toList(),
      attendanceWeekPresent: (attendanceWeek['present'] as num).toInt(),
      attendanceWeekTotal: (attendanceWeek['total_days'] as num).toInt(),
      attendanceMonthPresent: (attendanceMonth['present'] as num).toInt(),
      attendanceMonthTotal: (attendanceMonth['total_days'] as num).toInt(),
      meritTotalPoints: (meritMonth['total_points'] as num).toInt(),
      meritDaysRecorded: (meritMonth['days_recorded'] as num).toInt(),
      meritMaxPointsPerDay: (meritMonth['max_points_per_day'] as num).toInt(),
    );
  }
}
