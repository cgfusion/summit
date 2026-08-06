import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/attendance/domain/entities/attendance_status.dart';

void main() {
  group('AttendanceStatus Enum Test', () {
    test('fromDb parses valid status strings correctly', () {
      expect(AttendanceStatus.fromDb('hadir'), equals(AttendanceStatus.hadir));
      expect(AttendanceStatus.fromDb('lewat'), equals(AttendanceStatus.lewat));
      expect(AttendanceStatus.fromDb('tidak_hadir'), equals(AttendanceStatus.tidakHadir));
      expect(AttendanceStatus.fromDb('cuti_sakit'), equals(AttendanceStatus.cutiSakit));
      expect(AttendanceStatus.fromDb('urusan_rasmi'), equals(AttendanceStatus.urusanRasmi));
    });

    test('fromDb throws ArgumentError on unknown string', () {
      expect(() => AttendanceStatus.fromDb('invalid_status'), throwsArgumentError);
    });

    test('dbValue returns correct Postgres string', () {
      expect(AttendanceStatus.hadir.dbValue, equals('hadir'));
      expect(AttendanceStatus.tidakHadir.dbValue, equals('tidak_hadir'));
    });

    test('label returns proper Malay display label', () {
      expect(AttendanceStatus.hadir.label, equals('Hadir'));
      expect(AttendanceStatus.cutiSakit.label, equals('Cuti Sakit'));
    });
  });
}
