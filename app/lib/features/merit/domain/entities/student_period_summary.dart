class StudentPeriodSummary {
  const StudentPeriodSummary({
    required this.studentId,
    required this.fullName,
    required this.classId,
    required this.totalPoints,
    required this.maxPoints,
    required this.pct,
    required this.fullAttendance,
    required this.daysPresent,
    required this.daysAbsent,
  });

  final String studentId;
  final String fullName;
  final String? classId;
  final int totalPoints;
  final int maxPoints;
  final double pct;
  final bool fullAttendance;
  final int daysPresent;
  final int daysAbsent;

  factory StudentPeriodSummary.fromMap(Map<String, dynamic> map) {
    return StudentPeriodSummary(
      studentId: map['student_id'] as String,
      fullName: map['full_name'] as String,
      classId: map['class_id'] as String?,
      totalPoints: (map['total_points'] as num).toInt(),
      maxPoints: (map['max_points'] as num).toInt(),
      pct: (map['pct'] as num).toDouble(),
      fullAttendance: map['full_attendance'] as bool,
      daysPresent: (map['days_present'] as num).toInt(),
      daysAbsent: (map['days_absent'] as num).toInt(),
    );
  }
}
