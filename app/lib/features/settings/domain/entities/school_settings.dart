class SchoolSettings {
  const SchoolSettings({
    required this.programStartDate,
    required this.programEndDate,
    required this.schoolTimezone,
    required this.meritEnableHadir,
    required this.meritEnableTepatMasa,
    required this.meritEnableKembaliRehat,
    required this.meritEnableKekalSesi,
    required this.meritEnableBonus,
    required this.meritMaxPoints,
  });

  final DateTime programStartDate;
  final DateTime programEndDate;
  final String schoolTimezone;

  /// Which of the 4 daily merit components (plus bonus) currently count
  /// toward merit points. A disabled component always contributes 0,
  /// regardless of the underlying attendance/exception data -- see
  /// merit_student_daily.
  final bool meritEnableHadir;
  final bool meritEnableTepatMasa;
  final bool meritEnableKembaliRehat;
  final bool meritEnableKekalSesi;
  final bool meritEnableBonus;

  /// Max merit points achievable per day. Set independently of which
  /// components are enabled -- the admin keeps it in sync manually.
  final int meritMaxPoints;

  factory SchoolSettings.fromMap(Map<String, dynamic> map) {
    return SchoolSettings(
      programStartDate: DateTime.parse(map['program_start_date'] as String),
      programEndDate: DateTime.parse(map['program_end_date'] as String),
      schoolTimezone: map['school_timezone'] as String,
      meritEnableHadir: map['merit_enable_hadir'] as bool,
      meritEnableTepatMasa: map['merit_enable_tepat_masa'] as bool,
      meritEnableKembaliRehat: map['merit_enable_kembali_rehat'] as bool,
      meritEnableKekalSesi: map['merit_enable_kekal_sesi'] as bool,
      meritEnableBonus: map['merit_enable_bonus'] as bool,
      meritMaxPoints: map['merit_max_points'] as int,
    );
  }
}
