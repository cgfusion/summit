import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/discipline_counseling/domain/entities/sudut_info_post.dart';

void main() {
  group('SudutInfoPost Entity Tests', () {
    test('isCurrentlyActive returns true for published post within valid date range', () {
      final post = SudutInfoPost(
        id: 'post-1',
        category: 'disiplin',
        title: 'Kempen Sahsiah Terpuji',
        content: 'Format <b>HTML</b> test',
        managedBy: 'Unit Disiplin',
        isPublished: true,
        validFrom: DateTime.now().subtract(const Duration(days: 1)),
        validUntil: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
      );

      expect(post.isCurrentlyActive, isTrue);
      expect(post.statusLabel, equals('AKTIF (LIVE)'));
    });

    test('isScheduled returns true when validFrom is in the future', () {
      final post = SudutInfoPost(
        id: 'post-2',
        category: 'kaunseling',
        title: 'Minggu Kaunseling UBK',
        content: 'Akan datang',
        managedBy: 'Unit Bimbingan & Kaunseling',
        isPublished: true,
        validFrom: DateTime.now().add(const Duration(days: 2)),
        validUntil: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
      );

      expect(post.isCurrentlyActive, isFalse);
      expect(post.isScheduled, isTrue);
      expect(post.statusLabel, equals('DIJADUALKAN'));
    });

    test('isExpired returns true when validUntil is in the past', () {
      final post = SudutInfoPost(
        id: 'post-3',
        category: 'sekolah',
        title: 'Hebahan Tamat',
        content: 'Tamat',
        managedBy: 'Pentadbiran',
        isPublished: true,
        validFrom: DateTime.now().subtract(const Duration(days: 10)),
        validUntil: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
      );

      expect(post.isCurrentlyActive, isFalse);
      expect(post.isExpired, isTrue);
      expect(post.statusLabel, equals('TAMAT TEMPOH'));
    });

    test('fromMap deserializes database JSON correctly', () {
      final map = {
        'id': 'post-100',
        'author_id': 'author-123',
        'author_name': 'Cikgu Ahmad',
        'category': 'sahsiah',
        'title': 'Anugerah Sahsiah Terpuji',
        'content': 'Tahniah kepada semua pemenang.',
        'image_url': 'https://example.com/poster.jpg',
        'managed_by': 'Unit Disiplin & Kaunseling',
        'is_published': true,
        'valid_from': '2026-08-01T00:00:00.000Z',
        'valid_until': null,
        'created_at': '2026-08-01T00:00:00.000Z',
      };

      final post = SudutInfoPost.fromMap(map);
      expect(post.id, equals('post-100'));
      expect(post.authorName, equals('Cikgu Ahmad'));
      expect(post.category, equals('sahsiah'));
      expect(post.imageUrl, equals('https://example.com/poster.jpg'));
      expect(post.validUntil, isNull);
    });
  });
}
