import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/parent_portal/domain/entities/parent_portal_data.dart';

void main() {
  group('ParentIcLookupParams Test', () {
    test('ParentIcLookupParams records equality and hashcode', () {
      final p1 = (parentIc: '820315-12-5432', childIc: null);
      final p2 = (parentIc: '820315-12-5432', childIc: null);
      final p3 = (parentIc: '820315-12-5432', childIc: '100412-12-6543');

      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });

    test('ParentPortalData.fromMap handles list result from fn_parent_portal_data_by_ic', () {
      final map = {
        'student': {
          'full_name': 'MUHAMMAD ALIF',
          'class_name': '1 INSPIRA',
          'enrollment_status': 'active',
          'enrollment_status_reason': null,
          'enrollment_status_date': null,
        },
        'attendance_recent': [
          {'date': '2026-08-04', 'status': 'hadir'}
        ],
        'attendance_week': {'present': 4, 'total_days': 5},
        'attendance_month': {'present': 18, 'total_days': 20},
        'merit_month': {'total_points': 85, 'days_recorded': 18, 'max_points_per_day': 5},
      };

      final data = ParentPortalData.fromMap(map);
      expect(data.studentFullName, equals('MUHAMMAD ALIF'));
      expect(data.className, equals('1 INSPIRA'));
      expect(data.attendanceWeekPresent, equals(4));
    });
  });
}
