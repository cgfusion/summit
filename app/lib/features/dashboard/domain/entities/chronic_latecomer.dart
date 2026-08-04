/// A student with several 'lewat' days within a trailing window ending at
/// a reference date.
class ChronicLatecomer {
  const ChronicLatecomer({
    required this.studentId,
    required this.fullName,
    required this.classId,
    required this.className,
    required this.lateCount,
  });

  final String studentId;
  final String fullName;
  final String? classId;
  final String className;
  final int lateCount;

  factory ChronicLatecomer.fromMap(Map<String, dynamic> map) {
    return ChronicLatecomer(
      studentId: map['student_id'] as String,
      fullName: map['full_name'] as String,
      classId: map['class_id'] as String?,
      className: map['class_name'] as String,
      lateCount: (map['late_count'] as num).toInt(),
    );
  }
}
