import 'package:app/features/student_portal/domain/entities/student_portal_data.dart';
import 'package:app/features/student_portal/domain/entities/student_voice_submission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Student Voice & Portal Entities Test', () {
    test('StudentVoiceSubmission.fromMap deserializes database JSON correctly', () {
      final map = {
        'id': 'voice-123',
        'student_id': 'stud-456',
        'category': 'aduan_buli_keselamatan',
        'is_anonymous': true,
        'subject': 'Aduan Buli Siber',
        'message': 'Terdapat perbuatan buli dalam kumpulan WhatsApp kelas.',
        'status': 'dalam_tindakan',
        'response_notes': 'Siasatan sedang dijalankan oleh UBK.',
        'created_at': '2026-08-11T10:00:00Z',
        'students': {
          'full_name': 'Murid Rahsia',
          'classes': {'name': '3 CITRA'},
        },
        'profiles': {'full_name': 'Guru Kaunselor'},
      };

      final sub = StudentVoiceSubmission.fromMap(map);

      expect(sub.id, 'voice-123');
      expect(sub.category, 'aduan_buli_keselamatan');
      expect(sub.isAnonymous, isTrue);
      expect(sub.subject, 'Aduan Buli Siber');
      expect(sub.message, 'Terdapat perbuatan buli dalam kumpulan WhatsApp kelas.');
      expect(sub.status, 'dalam_tindakan');
      expect(sub.responseNotes, 'Siasatan sedang dijalankan oleh UBK.');
      expect(StudentVoiceSubmission.categoryLabel(sub.category), 'Aduan Buli & Keselamatan Murid');
    });

    test('StudentPortalData.fromMap deserializes RPC JSON response correctly', () {
      final map = {
        'student': {
          'id': 'stud-456',
          'full_name': 'Ahmad Farish',
          'class_name': '2 CITRA',
          'enrollment_status': 'active',
        },
        'attendance': {
          'total_days': 40,
          'days_present': 36,
          'days_absent': 4,
          'attendance_rate': 90.0,
        },
        'merit': {
          'total_points': 450,
        },
        'recent_attendance': [
          {'date': '2026-08-11', 'status': 'hadir'},
        ],
        'submissions': [
          {
            'id': 'voice-100',
            'category': 'cadangan_sekolah',
            'is_anonymous': false,
            'subject': 'Kelab Catur',
            'message': 'Dicadangkan tambah papan catur di perpustakaan.',
            'status': 'selesai',
            'created_at': '2026-08-11T09:00:00Z',
          }
        ],
      };

      final data = StudentPortalData.fromMap(map);

      expect(data.studentId, 'stud-456');
      expect(data.fullName, 'Ahmad Farish');
      expect(data.className, '2 CITRA');
      expect(data.totalDays, 40);
      expect(data.daysPresent, 36);
      expect(data.daysAbsent, 4);
      expect(data.attendanceRate, 90.0);
      expect(data.totalMeritPoints, 450);
      expect(data.recentAttendance.length, 1);
      expect(data.submissions.length, 1);
      expect(data.submissions.first.subject, 'Kelab Catur');
    });
  });
}
