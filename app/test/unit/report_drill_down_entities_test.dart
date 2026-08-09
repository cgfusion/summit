import 'package:app/features/reports/domain/entities/report_drill_down_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepeatAbsentStudentDetail', () {
    test('calculates attendance rate correctly', () {
      const detail = RepeatAbsentStudentDetail(
        studentId: 'uuid-1',
        fullName: 'Ahmad Abu',
        classId: 'class-1',
        className: '1 Inspira',
        session: 'petang',
        absentCount: 4,
        presentCount: 16,
        totalDays: 20,
      );

      expect(detail.attendanceRate, equals(80.0));
    });

    test('returns 0.0 attendance rate when totalDays is 0', () {
      const detail = RepeatAbsentStudentDetail(
        studentId: 'uuid-2',
        fullName: 'Siti Ali',
        classId: 'class-1',
        className: '1 Inspira',
        session: 'petang',
        absentCount: 0,
        presentCount: 0,
        totalDays: 0,
      );

      expect(detail.attendanceRate, equals(0.0));
    });
  });

  group('ClassAttendanceRateDetail', () {
    test('holds correct values', () {
      const detail = ClassAttendanceRateDetail(
        classId: 'class-1',
        className: '1 Inspira',
        formLevel: 1,
        session: 'petang',
        homeroomTeacherName: 'Cikgu Rahman',
        totalRecords: 100,
        presentCount: 92,
        absentCount: 8,
        attendanceRate: 92.0,
      );

      expect(detail.className, equals('1 Inspira'));
      expect(detail.attendanceRate, equals(92.0));
      expect(detail.homeroomTeacherName, equals('Cikgu Rahman'));
    });
  });
}
