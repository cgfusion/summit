class AttendanceLog {
  const AttendanceLog({
    required this.id,
    required this.studentId,
    required this.scannedAt,
    this.scannedBy,
    this.deviceLabel,
  });

  final String id;
  final String studentId;
  final DateTime scannedAt;
  final String? scannedBy;
  final String? deviceLabel;

  factory AttendanceLog.fromMap(Map<String, dynamic> map) {
    return AttendanceLog(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      scannedAt: DateTime.parse(map['scanned_at'] as String),
      scannedBy: map['scanned_by'] as String?,
      deviceLabel: map['device_label'] as String?,
    );
  }
}
