import 'student_voice_submission.dart';
import 'package:app/features/discipline_counseling/domain/entities/school_announcement.dart';

class StudentPortalData {
  const StudentPortalData({
    required this.studentId,
    required this.fullName,
    required this.className,
    required this.totalDays,
    required this.daysPresent,
    required this.daysAbsent,
    required this.attendanceRate,
    required this.totalMeritPoints,
    required this.recentAttendance,
    required this.submissions,
    required this.announcements,
  });

  final String studentId;
  final String fullName;
  final String className;
  final int totalDays;
  final int daysPresent;
  final int daysAbsent;
  final double attendanceRate;
  final int totalMeritPoints;
  final List<Map<String, dynamic>> recentAttendance;
  final List<StudentVoiceSubmission> submissions;
  final List<SchoolAnnouncement> announcements;

  factory StudentPortalData.fromMap(Map<String, dynamic> map) {
    final sMap = map['student'] as Map<String, dynamic>? ?? {};
    final aMap = map['attendance'] as Map<String, dynamic>? ?? {};
    final mMap = map['merit'] as Map<String, dynamic>? ?? {};
    final recentList = (map['recent_attendance'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final subList = (map['submissions'] as List?)
            ?.map((e) => StudentVoiceSubmission.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];
    final annList = (map['announcements'] as List?)
            ?.map((e) => SchoolAnnouncement.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    return StudentPortalData(
      studentId: sMap['id'] as String? ?? '',
      fullName: sMap['full_name'] as String? ?? 'Murid',
      className: sMap['class_name'] as String? ?? 'Tiada Kelas',
      totalDays: (aMap['total_days'] as num? ?? 0).toInt(),
      daysPresent: (aMap['days_present'] as num? ?? 0).toInt(),
      daysAbsent: (aMap['days_absent'] as num? ?? 0).toInt(),
      attendanceRate: (aMap['attendance_rate'] as num? ?? 100.0).toDouble(),
      totalMeritPoints: (mMap['total_points'] as num? ?? 0).toInt(),
      recentAttendance: recentList,
      submissions: subList,
      announcements: annList,
    );
  }
}
