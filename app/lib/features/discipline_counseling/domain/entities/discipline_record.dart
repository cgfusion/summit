class DisciplineRecord {
  const DisciplineRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.reporterId,
    required this.reporterName,
    required this.incidentDate,
    required this.category,
    required this.severity,
    required this.actionTaken,
    required this.status,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String reporterId;
  final String reporterName;
  final DateTime incidentDate;
  final String category;
  final String severity; // 'ringan', 'sederhana', 'berat'
  final String actionTaken; // 'Nasihat', 'Amaran Lisan', 'Surat Amaran 1', 'Surat Amaran 2', 'Surat Amaran 3', 'Rujukan UBK'
  final String status; // 'dalam_siasatan', 'dirujuk_ubk', 'selesai'
  final String? description;
  final DateTime createdAt;

  factory DisciplineRecord.fromMap(Map<String, dynamic> map) {
    final studentMap = map['students'] as Map<String, dynamic>?;
    final classMap = studentMap?['classes'] as Map<String, dynamic>?;
    final reporterMap = map['profiles'] as Map<String, dynamic>?;

    return DisciplineRecord(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: studentMap?['full_name'] as String? ?? map['student_name'] as String? ?? 'Murid',
      className: classMap?['name'] as String? ?? map['class_name'] as String? ?? 'Tiada Kelas',
      reporterId: map['reporter_id'] as String,
      reporterName: reporterMap?['full_name'] as String? ?? map['reporter_name'] as String? ?? 'Guru',
      incidentDate: DateTime.parse(map['incident_date'] as String),
      category: map['category'] as String,
      severity: map['severity'] as String? ?? 'ringan',
      actionTaken: map['action_taken'] as String? ?? 'Nasihat',
      status: map['status'] as String? ?? 'dalam_siasatan',
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
