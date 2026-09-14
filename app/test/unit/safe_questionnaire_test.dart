import 'package:app/features/discipline_counseling/domain/entities/safe_questionnaire.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeQuestionnaireResult.fromMap', () {
    test('computes level/memahami correctly per the documented >=75% threshold', () {
      final result = SafeQuestionnaireResult.fromMap({
        'items': [5, 4, 5, 4, 3, 3, 4, 3, 5, 5, 4, 5],
        'total_score': 50,
        'max_score': 60,
        'percent': 83.3,
        'level': 'tinggi',
        'memahami': true,
        'section_a_score': 18,
        'section_b_score': 13,
        'section_c_score': 19,
        'submitted_at': '2026-09-14T03:28:29.279295+00:00',
        'updated_at': '2026-09-14T03:28:29.279295+00:00',
      });

      expect(result.totalScore, 50);
      expect(result.maxScore, 60);
      expect(result.percent, 83.3);
      expect(result.level, SafeQuestionnaireLevel.tinggi);
      expect(result.memahami, isTrue);
      expect(result.sectionAScore + result.sectionBScore + result.sectionCScore, result.totalScore);
      expect(result.items, hasLength(12));
    });

    test('SafeQuestionnaireLevel.fromDb round-trips all three levels', () {
      expect(SafeQuestionnaireLevel.fromDb('rendah'), SafeQuestionnaireLevel.rendah);
      expect(SafeQuestionnaireLevel.fromDb('sederhana'), SafeQuestionnaireLevel.sederhana);
      expect(SafeQuestionnaireLevel.fromDb('tinggi'), SafeQuestionnaireLevel.tinggi);
      expect(() => SafeQuestionnaireLevel.fromDb('unknown'), throwsArgumentError);
    });
  });

  group('SafeQuestionnaireResponseRow.fromMap', () {
    test('computes percent as raw/60*100, not raw/40 -- the corrected denominator', () {
      final row = SafeQuestionnaireResponseRow.fromMap({
        'student_id': 'abc-123',
        'item_01': 5, 'item_02': 5, 'item_03': 5, 'item_04': 5,
        'item_05': 5, 'item_06': 5, 'item_07': 5, 'item_08': 5,
        'item_09': 5, 'item_10': 5, 'item_11': 5, 'item_12': 5,
        'submitted_at': '2026-09-14T00:00:00Z',
        'students': {
          'full_name': 'Test Student',
          'classes': {'name': '1 CITRA'},
        },
      });

      // All 5s across 12 items = 60/60 = 100%, not 60/40 = 150%.
      expect(row.totalScore, 60);
      expect(row.percent, 100.0);
      expect(row.level, SafeQuestionnaireLevel.tinggi);
      expect(row.studentName, 'Test Student');
      expect(row.className, '1 CITRA');
    });

    test('level bands follow percent, not the source document\'s non-tiling raw ranges', () {
      // Raw 30 out of 60 = 50% exactly -> sederhana (boundary is inclusive at 50).
      final row = SafeQuestionnaireResponseRow.fromMap({
        'student_id': 'abc-123',
        'item_01': 3, 'item_02': 3, 'item_03': 3, 'item_04': 3,
        'item_05': 2, 'item_06': 2, 'item_07': 3, 'item_08': 3,
        'item_09': 2, 'item_10': 2, 'item_11': 2, 'item_12': 2,
        'submitted_at': '2026-09-14T00:00:00Z',
        'students': {'full_name': 'Test', 'classes': null},
      });

      expect(row.totalScore, 30);
      expect(row.percent, 50.0);
      expect(row.level, SafeQuestionnaireLevel.sederhana);
      expect(row.className, isNull);
    });
  });

  test('safeQuestionnaireItems has exactly 12 items, 4 per section in document order', () {
    expect(safeQuestionnaireItems, hasLength(12));
    final sectionCounts = <SafeQuestionnaireSection, int>{};
    for (final item in safeQuestionnaireItems) {
      sectionCounts[item.section] = (sectionCounts[item.section] ?? 0) + 1;
    }
    expect(sectionCounts[SafeQuestionnaireSection.pengetahuanKesedaran], 4);
    expect(sectionCounts[SafeQuestionnaireSection.amalanSekolahPenyayang], 4);
    expect(sectionCounts[SafeQuestionnaireSection.perananPrs], 4);
  });
}
