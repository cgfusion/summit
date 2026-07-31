import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../merit/domain/value_objects/date_range.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/entities/kpi_trend_week.dart';
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
