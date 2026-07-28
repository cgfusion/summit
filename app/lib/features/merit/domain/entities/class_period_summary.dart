class ClassPeriodSummary {
  const ClassPeriodSummary({
    required this.classId,
    required this.className,
    required this.totalPoints,
    required this.maxPoints,
    required this.pct,
    required this.missedRecessReturnCount,
    required this.missedRecessReturnRate,
  });

  final String classId;
  final String className;
  final int totalPoints;
  final int maxPoints;
  final double pct;
  final int missedRecessReturnCount;
  final double missedRecessReturnRate;

  factory ClassPeriodSummary.fromMap(Map<String, dynamic> map) {
    return ClassPeriodSummary(
      classId: map['class_id'] as String,
      className: map['class_name'] as String,
      totalPoints: (map['total_points'] as num).toInt(),
      maxPoints: (map['max_points'] as num).toInt(),
      pct: (map['pct'] as num).toDouble(),
      missedRecessReturnCount: (map['missed_recess_return_count'] as num).toInt(),
      missedRecessReturnRate: (map['missed_recess_return_rate'] as num).toDouble(),
    );
  }
}
