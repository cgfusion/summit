enum MeritAwardCategory {
  fullWeeklyAttendance,
  fullMonthlyAttendance,
  individualImprovement,
  mostImprovedClass,
  bestTransition,
  highestMeritClass;

  String get dbValue => switch (this) {
        MeritAwardCategory.fullWeeklyAttendance => 'full_weekly_attendance',
        MeritAwardCategory.fullMonthlyAttendance => 'full_monthly_attendance',
        MeritAwardCategory.individualImprovement => 'individual_improvement',
        MeritAwardCategory.mostImprovedClass => 'most_improved_class',
        MeritAwardCategory.bestTransition => 'best_transition',
        MeritAwardCategory.highestMeritClass => 'highest_merit_class',
      };

  String get label => switch (this) {
        MeritAwardCategory.fullWeeklyAttendance => 'Kehadiran Penuh Mingguan',
        MeritAwardCategory.fullMonthlyAttendance => 'Kehadiran Penuh Bulanan',
        MeritAwardCategory.individualImprovement => 'Peningkatan Individu',
        MeritAwardCategory.mostImprovedClass => 'Kelas Paling Meningkat',
        MeritAwardCategory.bestTransition => 'Transisi Terbaik',
        MeritAwardCategory.highestMeritClass => 'Kelas Merit Tertinggi',
      };

  bool get isClassScoped =>
      this == MeritAwardCategory.mostImprovedClass ||
      this == MeritAwardCategory.bestTransition ||
      this == MeritAwardCategory.highestMeritClass;

  static MeritAwardCategory fromDb(String value) {
    return MeritAwardCategory.values.firstWhere((c) => c.dbValue == value);
  }
}

class MeritAward {
  const MeritAward({
    required this.id,
    required this.category,
    required this.scopeType,
    this.studentId,
    this.classId,
    required this.periodStart,
    required this.periodEnd,
    required this.awardedAt,
    this.note,
  });

  final String id;
  final MeritAwardCategory category;
  final String scopeType;
  final String? studentId;
  final String? classId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime awardedAt;
  final String? note;

  factory MeritAward.fromMap(Map<String, dynamic> map) {
    return MeritAward(
      id: map['id'] as String,
      category: MeritAwardCategory.fromDb(map['category'] as String),
      scopeType: map['scope_type'] as String,
      studentId: map['student_id'] as String?,
      classId: map['class_id'] as String?,
      periodStart: DateTime.parse(map['period_start'] as String),
      periodEnd: DateTime.parse(map['period_end'] as String),
      awardedAt: DateTime.parse(map['awarded_at'] as String),
      note: map['note'] as String?,
    );
  }
}
