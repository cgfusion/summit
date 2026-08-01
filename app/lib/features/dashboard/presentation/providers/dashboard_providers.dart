import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../class_management/presentation/providers/class_providers.dart';
import '../../../merit/presentation/providers/merit_providers.dart';
import '../../../student/presentation/providers/student_providers.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalClasses,
    required this.totalStudents,
    required this.attendanceRateToday,
    required this.totalMeritPoints,
    required this.totalRewardsGiven,
  });

  final int totalClasses;
  final int totalStudents;
  final double attendanceRateToday;
  final int totalMeritPoints;
  final int totalRewardsGiven;
}

/// Aggregates figures already served by each feature's own repository into
/// one summary for the dashboard's "Quick Overview" bar. Deliberately calls
/// the repositories directly (not the screen-level `studentsProvider`/
/// `attendanceForDateProvider`) so this isn't affected by whatever filter
/// state another screen happens to be left in.
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final classRepository = ref.watch(classRepositoryProvider);
  final studentRepository = ref.watch(studentRepositoryProvider);
  final attendanceRepository = ref.watch(attendanceRepositoryProvider);
  final meritRepository = ref.watch(meritRepositoryProvider);

  final classesFuture = classRepository.getClasses();
  final studentsFuture = studentRepository.getStudents();
  final attendanceTodayFuture = attendanceRepository.getAttendanceForDate(date: DateTime.now());
  final programPeriodFuture = meritRepository.getProgramPeriod();
  final totalRewardsFuture = meritRepository.getTotalAwardsCount();

  final classes = await classesFuture;
  final students = await studentsFuture;
  final attendanceToday = await attendanceTodayFuture;
  final programPeriod = await programPeriodFuture;
  final totalRewards = await totalRewardsFuture;

  final studentSummaries = await meritRepository.getStudentSummary(from: programPeriod.from, to: programPeriod.to);
  final totalMeritPoints = studentSummaries.fold<int>(0, (sum, s) => sum + s.totalPoints);

  final presentToday =
      attendanceToday.where((a) => a.status == AttendanceStatus.hadir || a.status == AttendanceStatus.lewat).length;
  final attendanceRateToday = students.isEmpty ? 0.0 : presentToday / students.length;

  return DashboardStats(
    totalClasses: classes.length,
    totalStudents: students.length,
    attendanceRateToday: attendanceRateToday,
    totalMeritPoints: totalMeritPoints,
    totalRewardsGiven: totalRewards,
  );
});
