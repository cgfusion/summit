class StudentVoiceSubmission {
  const StudentVoiceSubmission({
    required this.id,
    this.studentId,
    this.studentName,
    this.className,
    required this.category,
    required this.isAnonymous,
    required this.subject,
    required this.message,
    required this.status,
    this.responseNotes,
    this.respondedByName,
    required this.createdAt,
  });

  final String id;
  final String? studentId;
  final String? studentName;
  final String? className;
  final String category; // 'cadangan_sekolah', 'maklum_balas_pembelajaran', 'aduan_buli_keselamatan', 'permohonan_kaunseling'
  final bool isAnonymous;
  final String subject;
  final String message;
  final String status; // 'baru', 'dalam_tindakan', 'selesai'
  final String? responseNotes;
  final String? respondedByName;
  final DateTime createdAt;

  factory StudentVoiceSubmission.fromMap(Map<String, dynamic> map) {
    final studentMap = map['students'] as Map<String, dynamic>?;
    final classMap = studentMap?['classes'] as Map<String, dynamic>?;
    final responderMap = map['profiles'] as Map<String, dynamic>?;

    return StudentVoiceSubmission(
      id: map['id'] as String,
      studentId: map['student_id'] as String?,
      studentName: studentMap?['full_name'] as String?,
      className: classMap?['name'] as String?,
      category: map['category'] as String? ?? 'cadangan_sekolah',
      isAnonymous: map['is_anonymous'] as bool? ?? false,
      subject: map['subject'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'baru',
      responseNotes: map['response_notes'] as String?,
      respondedByName: responderMap?['full_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static String categoryLabel(String category) {
    return switch (category) {
      'cadangan_sekolah' => 'Cadangan Penambahbaikan Sekolah',
      'maklum_balas_pembelajaran' => 'Maklum Balas Pembelajaran & Kelas',
      'aduan_buli_keselamatan' => 'Aduan Buli & Keselamatan Murid',
      'permohonan_kaunseling' => 'Permohonan Sesi Kaunseling UBK',
      _ => category,
    };
  }
}
