class CounselingRecord {
  const CounselingRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.counselorId,
    required this.counselorName,
    this.disciplineRecordId,
    required this.sessionDate,
    required this.sessionType,
    required this.focusArea,
    this.outcomeNotes,
    required this.followUpStatus,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String counselorId;
  final String counselorName;
  final String? disciplineRecordId;
  final DateTime sessionDate;
  final String sessionType; // 'individu', 'kelompok', 'ibu_bapa'
  final String focusArea; // 'sahsiah_disiplin', 'akademik', 'kerjaya', 'psikososial'
  final String? outcomeNotes;
  final String followUpStatus; // 'memerlukan_susulan', 'selesai'
  final DateTime createdAt;

  factory CounselingRecord.fromMap(Map<String, dynamic> map) {
    final studentMap = map['students'] as Map<String, dynamic>?;
    final classMap = studentMap?['classes'] as Map<String, dynamic>?;
    final counselorMap = map['profiles'] as Map<String, dynamic>?;

    return CounselingRecord(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: studentMap?['full_name'] as String? ?? map['student_name'] as String? ?? 'Murid',
      className: classMap?['name'] as String? ?? map['class_name'] as String? ?? 'Tiada Kelas',
      counselorId: map['counselor_id'] as String,
      counselorName: counselorMap?['full_name'] as String? ?? map['counselor_name'] as String? ?? 'Guru Kaunselor',
      disciplineRecordId: map['discipline_record_id'] as String?,
      sessionDate: DateTime.parse(map['session_date'] as String),
      sessionType: map['session_type'] as String? ?? 'individu',
      focusArea: map['focus_area'] as String? ?? 'sahsiah_disiplin',
      outcomeNotes: map['outcome_notes'] as String?,
      followUpStatus: map['follow_up_status'] as String? ?? 'memerlukan_susulan',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
