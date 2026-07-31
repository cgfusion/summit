class KpiTrendWeek {
  const KpiTrendWeek({
    required this.weekStart,
    required this.totalRecords,
    required this.presentCount,
    required this.lateCount,
    required this.attendanceRate,
    required this.missedRecessCount,
    required this.repeatAbsentStudents,
  });

  final DateTime weekStart;
  final int totalRecords;
  final int presentCount;
  final int lateCount;
  final double attendanceRate;
  final int missedRecessCount;
  final int repeatAbsentStudents;

  factory KpiTrendWeek.fromMap(Map<String, dynamic> map) {
    return KpiTrendWeek(
      weekStart: DateTime.parse(map['week_start'] as String),
      totalRecords: (map['total_records'] as num).toInt(),
      presentCount: (map['present_count'] as num).toInt(),
      lateCount: (map['late_count'] as num).toInt(),
      attendanceRate: (map['attendance_rate'] as num).toDouble(),
      missedRecessCount: (map['missed_recess_count'] as num).toInt(),
      repeatAbsentStudents: (map['repeat_absent_students'] as num).toInt(),
    );
  }
}
