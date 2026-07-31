import 'package:supabase_flutter/supabase_flutter.dart';

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
      'p_from': _dateOnly(from),
      'p_to': _dateOnly(to),
      'p_session': session,
    });
    return (rows as List).map((row) => KpiTrendWeek.fromMap(row as Map<String, dynamic>)).toList();
  }

  String _dateOnly(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }
}
