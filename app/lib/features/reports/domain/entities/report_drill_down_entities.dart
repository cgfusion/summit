class RepeatAbsentStudentDetail {
  const RepeatAbsentStudentDetail({
    required this.studentId,
    required this.fullName,
    required this.classId,
    required this.className,
    required this.session,
    required this.absentCount,
    required this.presentCount,
    required this.totalDays,
    this.icNumber,
  });

  final String studentId;
  final String fullName;
  final String classId;
  final String className;
  final String session;
  final int absentCount;
  final int presentCount;
  final int totalDays;
  final String? icNumber;

  double get attendanceRate => totalDays == 0 ? 0.0 : (presentCount / totalDays) * 100;
}

class ClassAttendanceRateDetail {
  const ClassAttendanceRateDetail({
    required this.classId,
    required this.className,
    required this.formLevel,
    required this.session,
    this.homeroomTeacherName,
    required this.totalRecords,
    required this.presentCount,
    required this.absentCount,
    required this.attendanceRate,
  });

  final String classId;
  final String className;
  final int formLevel;
  final String session;
  final String? homeroomTeacherName;
  final int totalRecords;
  final int presentCount;
  final int absentCount;
  final double attendanceRate;
}

class LateAndRecessStudentDetail {
  const LateAndRecessStudentDetail({
    required this.studentId,
    required this.fullName,
    required this.classId,
    required this.className,
    required this.session,
    required this.lateCount,
    required this.missedRecessCount,
  });

  final String studentId;
  final String fullName;
  final String classId;
  final String className;
  final String session;
  final int lateCount;
  final int missedRecessCount;
}

class LeaveRecordDetail {
  const LeaveRecordDetail({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.classId,
    required this.className,
    required this.session,
    required this.schoolDate,
    required this.status,
  });

  final String id;
  final String studentId;
  final String fullName;
  final String classId;
  final String className;
  final String session;
  final DateTime schoolDate;
  final String status;
}
