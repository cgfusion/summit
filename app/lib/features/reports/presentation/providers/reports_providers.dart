import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../merit/domain/value_objects/date_range.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/entities/kpi_trend_week.dart';
import '../../domain/entities/report_drill_down_entities.dart';
import '../../domain/repositories/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

/// Defaults to 'petang' since KPI 1 is specifically "peratus kehadiran sesi
/// petang" -- the D2C program's actual target population.
final reportsSessionFilterProvider = StateProvider<String?>((ref) => 'petang');

final weeklyKpiTrendProvider = FutureProvider.autoDispose.family<List<KpiTrendWeek>, DateRange>((ref, range) {
  final repository = ref.watch(reportsRepositoryProvider);
  final session = ref.watch(reportsSessionFilterProvider);
  return repository.getWeeklyKpiTrend(from: range.from, to: range.to, session: session);
});

final repeatAbsentStudentsProvider =
    FutureProvider.autoDispose.family<List<RepeatAbsentStudentDetail>, DateRange>((ref, range) {
  final repository = ref.watch(reportsRepositoryProvider);
  final session = ref.watch(reportsSessionFilterProvider);
  return repository.getRepeatAbsentStudents(from: range.from, to: range.to, session: session);
});

final classAttendanceRatesProvider =
    FutureProvider.autoDispose.family<List<ClassAttendanceRateDetail>, DateRange>((ref, range) {
  final repository = ref.watch(reportsRepositoryProvider);
  final session = ref.watch(reportsSessionFilterProvider);
  return repository.getClassAttendanceRates(from: range.from, to: range.to, session: session);
});

final lateAndRecessRecordsProvider =
    FutureProvider.autoDispose.family<List<LateAndRecessStudentDetail>, DateRange>((ref, range) {
  final repository = ref.watch(reportsRepositoryProvider);
  final session = ref.watch(reportsSessionFilterProvider);
  return repository.getLateAndRecessRecords(from: range.from, to: range.to, session: session);
});

final leaveRecordsProvider = FutureProvider.autoDispose
    .family<List<LeaveRecordDetail>, ({DateRange range, String? status})>((ref, arg) {
  final repository = ref.watch(reportsRepositoryProvider);
  final session = ref.watch(reportsSessionFilterProvider);
  return repository.getLeaveRecords(from: arg.range.from, to: arg.range.to, session: session, status: arg.status);
});
