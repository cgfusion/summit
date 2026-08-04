/// One class's (or, when [classId] is null, the whole school's) attendance
/// rate across 4 fixed timeframes anchored to one reference date. Week/
/// month/year rates use the FULL period's school-day count as denominator,
/// not days elapsed so far -- see fn_attendance_period_summary for why.
class AttendancePeriodSummary {
  const AttendancePeriodSummary({
    required this.classId,
    required this.className,
    required this.dayRate,
    required this.weekRate,
    required this.monthRate,
    required this.yearRate,
  });

  final String? classId;
  final String className;
  final double dayRate;
  final double weekRate;
  final double monthRate;
  final double yearRate;

  bool get isWholeSchool => classId == null;

  factory AttendancePeriodSummary.fromMap(Map<String, dynamic> map) {
    return AttendancePeriodSummary(
      classId: map['class_id'] as String?,
      className: map['class_name'] as String,
      dayRate: (map['day_rate'] as num).toDouble(),
      weekRate: (map['week_rate'] as num).toDouble(),
      monthRate: (map['month_rate'] as num).toDouble(),
      yearRate: (map['year_rate'] as num).toDouble(),
    );
  }
}
