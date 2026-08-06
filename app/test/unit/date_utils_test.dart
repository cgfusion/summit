import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/date_utils.dart';

void main() {
  group('DateUtils Test', () {
    test('dateOnly strips time components to 00:00:00', () {
      final input = DateTime(2026, 8, 6, 14, 30, 45, 123);
      final result = dateOnly(input);

      expect(result.year, equals(2026));
      expect(result.month, equals(8));
      expect(result.day, equals(6));
      expect(result.hour, equals(0));
      expect(result.minute, equals(0));
      expect(result.second, equals(0));
      expect(result.millisecond, equals(0));
    });

    test('formatDateOnly formats DateTime into YYYY-MM-DD string', () {
      final dt1 = DateTime(2026, 8, 6);
      expect(formatDateOnly(dt1), equals('2026-08-06'));

      final dt2 = DateTime(2026, 1, 15, 23, 59);
      expect(formatDateOnly(dt2), equals('2026-01-15'));
    });
  });
}
