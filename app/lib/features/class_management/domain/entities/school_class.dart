class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    required this.formLevel,
    required this.session,
    this.homeroomTeacherName,
    this.homeroomTeacherId,
  });

  final String id;
  final String name;
  final int formLevel;

  /// 'pagi' (morning, Tingkatan 3-5) or 'petang' (afternoon, Tingkatan 1-2).
  final String session;
  final String? homeroomTeacherName;
  final String? homeroomTeacherId;

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      id: map['id'] as String,
      name: map['name'] as String,
      formLevel: map['form_level'] as int,
      session: map['session'] as String,
      homeroomTeacherName: map['homeroom_teacher_name'] as String?,
      homeroomTeacherId: map['homeroom_teacher_id'] as String?,
    );
  }
}
