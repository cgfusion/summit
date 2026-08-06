import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/kpi_trend_week.dart';
import '../../domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<KpiTrendWeek>> getWeeklyKpiTrend({
    required DateTime from,
    required DateTime to,
    String? session,
  }) async {
    final rows = await _client.rpc('fn_weekly_kpi_trend', params: {
      'p_from': formatDateOnly(from),
      'p_to': formatDateOnly(to),
      'p_session': session,
    });
    return (rows as List).map((row) => KpiTrendWeek.fromMap(row as Map<String, dynamic>)).toList();
  }
}
