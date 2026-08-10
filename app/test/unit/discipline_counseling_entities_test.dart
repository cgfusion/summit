import 'package:app/features/discipline_counseling/domain/entities/counseling_record.dart';
import 'package:app/features/discipline_counseling/domain/entities/discipline_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Discipline & Counseling Entities Test', () {
    test('DisciplineRecord.fromMap deserializes database JSON map correctly', () {
      final map = {
        'id': 'disc-123',
        'student_id': 'stud-456',
        'reporter_id': 'teacher-789',
        'incident_date': '2026-08-11',
        'category': 'Ponteng Sekolah/Kelas',
        'severity': 'berat',
        'action_taken': 'Surat Amaran 1',
        'status': 'dalam_siasatan',
        'description': 'Ponteng 3 hari berturut-turut tanpa sebab',
        'created_at': '2026-08-11T08:00:00Z',
        'students': {
          'full_name': 'Ahmad Farish',
          'classes': {'name': '2 CITRA'},
        },
        'profiles': {'full_name': 'Guru Disiplin Ali'},
      };

      final record = DisciplineRecord.fromMap(map);

      expect(record.id, 'disc-123');
      expect(record.studentId, 'stud-456');
      expect(record.studentName, 'Ahmad Farish');
      expect(record.className, '2 CITRA');
      expect(record.reporterName, 'Guru Disiplin Ali');
      expect(record.category, 'Ponteng Sekolah/Kelas');
      expect(record.severity, 'berat');
      expect(record.actionTaken, 'Surat Amaran 1');
      expect(record.status, 'dalam_siasatan');
      expect(record.description, 'Ponteng 3 hari berturut-turut tanpa sebab');
    });

    test('CounselingRecord.fromMap deserializes database JSON map correctly', () {
      final map = {
        'id': 'couns-123',
        'student_id': 'stud-456',
        'counselor_id': 'counselor-789',
        'discipline_record_id': 'disc-123',
        'session_date': '2026-08-11',
        'session_type': 'individu',
        'focus_area': 'sahsiah_disiplin',
        'outcome_notes': 'Murid berjanji untuk hadir secara konsisten.',
        'follow_up_status': 'memerlukan_susulan',
        'created_at': '2026-08-11T09:00:00Z',
        'students': {
          'full_name': 'Ahmad Farish',
          'classes': {'name': '2 CITRA'},
        },
        'profiles': {'full_name': 'Cikgu Siti (UBK)'},
      };

      final record = CounselingRecord.fromMap(map);

      expect(record.id, 'couns-123');
      expect(record.studentId, 'stud-456');
      expect(record.studentName, 'Ahmad Farish');
      expect(record.className, '2 CITRA');
      expect(record.counselorName, 'Cikgu Siti (UBK)');
      expect(record.sessionType, 'individu');
      expect(record.focusArea, 'sahsiah_disiplin');
      expect(record.outcomeNotes, 'Murid berjanji untuk hadir secara konsisten.');
      expect(record.followUpStatus, 'memerlukan_susulan');
    });
  });
}
