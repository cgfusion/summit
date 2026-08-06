import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/student/domain/entities/enrollment_status.dart';

void main() {
  group('EnrollmentStatus Enum Test', () {
    test('fromDb parses valid database text values correctly', () {
      expect(EnrollmentStatus.fromDb('active'), equals(EnrollmentStatus.active));
      expect(EnrollmentStatus.fromDb('suspended'), equals(EnrollmentStatus.suspended));
      expect(EnrollmentStatus.fromDb('expelled'), equals(EnrollmentStatus.expelled));
      expect(EnrollmentStatus.fromDb('transferred_out'), equals(EnrollmentStatus.transferredOut));
      expect(EnrollmentStatus.fromDb('withdrawn'), equals(EnrollmentStatus.withdrawn));
      expect(EnrollmentStatus.fromDb('deceased'), equals(EnrollmentStatus.deceased));
      expect(EnrollmentStatus.fromDb('graduated'), equals(EnrollmentStatus.graduated));
    });

    test('fromDb throws ArgumentError for invalid status value', () {
      expect(() => EnrollmentStatus.fromDb('unknown_status'), throwsArgumentError);
    });

    test('dbValue returns correct database text representation', () {
      expect(EnrollmentStatus.active.dbValue, equals('active'));
      expect(EnrollmentStatus.expelled.dbValue, equals('expelled'));
      expect(EnrollmentStatus.transferredOut.dbValue, equals('transferred_out'));
    });

    test('label returns bilingual strings', () {
      expect(EnrollmentStatus.active.label, contains('Active'));
      expect(EnrollmentStatus.expelled.label, contains('Dibuang Sekolah'));
    });
  });
}
