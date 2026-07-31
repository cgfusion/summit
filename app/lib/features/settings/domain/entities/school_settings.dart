class SchoolSettings {
  const SchoolSettings({
    required this.programStartDate,
    required this.programEndDate,
    required this.schoolTimezone,
  });

  final DateTime programStartDate;
  final DateTime programEndDate;
  final String schoolTimezone;

  factory SchoolSettings.fromMap(Map<String, dynamic> map) {
    return SchoolSettings(
      programStartDate: DateTime.parse(map['program_start_date'] as String),
      programEndDate: DateTime.parse(map['program_end_date'] as String),
      schoolTimezone: map['school_timezone'] as String,
    );
  }
}
