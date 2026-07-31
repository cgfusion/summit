import '../entities/kpi_trend_week.dart';

abstract interface class ReportsRepository {
  /// Weekly KPI trend per KK D2C.docx section 18.0. [session] filters to
  /// 'pagi'/'petang', or null for the whole school.
  Future<List<KpiTrendWeek>> getWeeklyKpiTrend({
    required DateTime from,
    required DateTime to,
    String? session,
  });
}
