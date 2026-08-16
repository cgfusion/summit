class SchoolAnnouncement {
  const SchoolAnnouncement({
    required this.id,
    this.authorId,
    this.authorName,
    required this.category, // 'disiplin' or 'kaunseling'
    required this.title,
    required this.content,
    this.targetStudentId,
    this.targetStudentName,
    required this.isPublished,
    required this.createdAt,
  });

  final String id;
  final String? authorId;
  final String? authorName;
  final String category;
  final String title;
  final String content;
  final String? targetStudentId;
  final String? targetStudentName;
  final bool isPublished;
  final DateTime createdAt;

  factory SchoolAnnouncement.fromMap(Map<String, dynamic> map) {
    final authorMap = map['profiles'] as Map<String, dynamic>?;
    final studentMap = map['students'] as Map<String, dynamic>?;

    return SchoolAnnouncement(
      id: map['id'] as String,
      authorId: map['author_id'] as String?,
      authorName: authorMap?['full_name'] as String? ?? map['author_name'] as String?,
      category: map['category'] as String? ?? 'disiplin',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      targetStudentId: map['target_student_id'] as String?,
      targetStudentName: studentMap?['full_name'] as String? ?? map['target_student_name'] as String?,
      isPublished: map['is_published'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
