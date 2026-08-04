enum AttendanceSummaryScope { school, form, class_ }

/// One row's attendance stats across 4 fixed timeframes anchored to one
/// reference date: the whole school, one Tingkatan (form level), or one
/// class. Week/month/year use the FULL period's school-day count as
/// denominator, not days elapsed so far -- see fn_attendance_period_summary
/// for why. Both the rounded rate and the raw present/total counts behind
/// it are exposed, since the counts have their own dedicated view.
class AttendancePeriodSummary {
  const AttendancePeriodSummary({
    required this.scope,
    required this.scopeId,
    required this.scopeName,
    required this.studentCount,
    required this.dayPresent,
    required this.dayTotal,
    required this.dayRate,
    required this.weekPresent,
    required this.weekTotal,
    required this.weekRate,
    required this.monthPresent,
    required this.monthTotal,
    required this.monthRate,
    required this.yearPresent,
    required this.yearTotal,
    required this.yearRate,
  });

  final AttendanceSummaryScope scope;
  final String? scopeId;
  final String scopeName;
  final int studentCount;

  final int dayPresent;
  final int dayTotal;
  final double dayRate;

  final int weekPresent;
  final int weekTotal;
  final double weekRate;

  final int monthPresent;
  final int monthTotal;
  final double monthRate;

  final int yearPresent;
  final int yearTotal;
  final double yearRate;

  factory AttendancePeriodSummary.fromMap(Map<String, dynamic> map) {
    final scope = switch (map['scope_type'] as String) {
      'school' => AttendanceSummaryScope.school,
      'form' => AttendanceSummaryScope.form,
      _ => AttendanceSummaryScope.class_,
    };
    return AttendancePeriodSummary(
      scope: scope,
      scopeId: map['scope_id'] as String?,
      scopeName: map['scope_name'] as String,
      studentCount: (map['student_count'] as num).toInt(),
      dayPresent: (map['day_present'] as num).toInt(),
      dayTotal: (map['day_total'] as num).toInt(),
      dayRate: (map['day_rate'] as num).toDouble(),
      weekPresent: (map['week_present'] as num).toInt(),
      weekTotal: (map['week_total'] as num).toInt(),
      weekRate: (map['week_rate'] as num).toDouble(),
      monthPresent: (map['month_present'] as num).toInt(),
      monthTotal: (map['month_total'] as num).toInt(),
      monthRate: (map['month_rate'] as num).toDouble(),
      yearPresent: (map['year_present'] as num).toInt(),
      yearTotal: (map['year_total'] as num).toInt(),
      yearRate: (map['year_rate'] as num).toDouble(),
    );
  }
}
