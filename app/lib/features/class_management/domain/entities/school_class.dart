class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    required this.formLevel,
    this.homeroomTeacherName,
    this.homeroomTeacherId,
  });

  final String id;
  final String name;
  final int formLevel;
  final String? homeroomTeacherName;
  final String? homeroomTeacherId;

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      id: map['id'] as String,
      name: map['name'] as String,
      formLevel: map['form_level'] as int,
      homeroomTeacherName: map['homeroom_teacher_name'] as String?,
      homeroomTeacherId: map['homeroom_teacher_id'] as String?,
    );
  }
}
