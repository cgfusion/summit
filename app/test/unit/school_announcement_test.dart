import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/discipline_counseling/domain/entities/school_announcement.dart';

void main() {
  group('SchoolAnnouncement Entity Test', () {
    test('fromMap deserializes database JSON map correctly for Discipline category', () {
      final map = {
        'id': 'ann-123',
        'author_id': 'user-456',
        'category': 'disiplin',
        'title': 'Peringatan Kekemasan Diri',
        'content': 'Sila pastikan pakaian dan rambut mengikut peraturan sekolah.',
        'target_student_id': 'student-789',
        'is_published': true,
        'created_at': '2026-08-16T10:00:00Z',
        'profiles': {'full_name': 'Cikgu Ahmad'},
        'students': {'full_name': 'Ali Bin Abu'},
      };

      final ann = SchoolAnnouncement.fromMap(map);

      expect(ann.id, equals('ann-123'));
      expect(ann.category, equals('disiplin'));
      expect(ann.title, equals('Peringatan Kekemasan Diri'));
      expect(ann.authorName, equals('Cikgu Ahmad'));
      expect(ann.targetStudentName, equals('Ali Bin Abu'));
      expect(ann.isPublished, isTrue);
    });

    test('fromMap deserializes Counseling UBK category correctly', () {
      final map = {
        'id': 'ann-456',
        'category': 'kaunseling',
        'title': 'Sesi Bimbingan Kerjaya',
        'content': 'Sesi bimbingan khas bertempat di Bilik UBK.',
        'created_at': '2026-08-16T14:30:00Z',
      };

      final ann = SchoolAnnouncement.fromMap(map);

      expect(ann.category, equals('kaunseling'));
      expect(ann.authorName, isNull);
      expect(ann.targetStudentName, isNull);
    });
  });
}
