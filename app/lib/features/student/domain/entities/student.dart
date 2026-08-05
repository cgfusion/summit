import 'enrollment_status.dart';

class Student {
  const Student({
    required this.id,
    required this.studentId,
    required this.fullName,
    this.icNumber,
    this.icType,
    this.dateOfBirth,
    this.gender,
    required this.studyStatus,
    this.enrolledAt,
    this.classJoinedAt,
    this.classId,
    this.className,
    this.enrollmentStatus = EnrollmentStatus.active,
    this.enrollmentStatusReason,
    this.enrollmentStatusDate,
  });

  final String id;
  final int studentId;
  final String fullName;
  final String? icNumber;
  final String? icType;
  final DateTime? dateOfBirth;
  final String? gender;
  final String studyStatus;
  final DateTime? enrolledAt;
  final DateTime? classJoinedAt;
  final String? classId;
  final String? className;
  final EnrollmentStatus enrollmentStatus;
  final String? enrollmentStatusReason;
  final DateTime? enrollmentStatusDate;

  factory Student.fromMap(Map<String, dynamic> map) {
    final classRow = map['classes'] as Map<String, dynamic>?;
    return Student(
      id: map['id'] as String,
      studentId: map['student_id'] as int,
      fullName: map['full_name'] as String,
      icNumber: map['ic_number'] as String?,
      icType: map['ic_type'] as String?,
      dateOfBirth: map['date_of_birth'] == null ? null : DateTime.parse(map['date_of_birth'] as String),
      gender: map['gender'] as String?,
      studyStatus: map['study_status'] as String,
      enrolledAt: map['enrolled_at'] == null ? null : DateTime.parse(map['enrolled_at'] as String),
      classJoinedAt: map['class_joined_at'] == null ? null : DateTime.parse(map['class_joined_at'] as String),
      classId: map['class_id'] as String?,
      className: classRow?['name'] as String?,
      enrollmentStatus: map['enrollment_status'] == null
          ? EnrollmentStatus.active
          : EnrollmentStatus.fromDb(map['enrollment_status'] as String),
      enrollmentStatusReason: map['enrollment_status_reason'] as String?,
      enrollmentStatusDate: map['enrollment_status_date'] == null
          ? null
          : DateTime.parse(map['enrollment_status_date'] as String),
    );
  }
}
