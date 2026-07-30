import '../entities/class_period_summary.dart';
import '../entities/merit_award.dart';
import '../entities/merit_day.dart';
import '../entities/student_period_summary.dart';
import '../value_objects/date_range.dart';

abstract interface class MeritRepository {
  Future<DateRange> getProgramPeriod();

  Future<List<MeritDay>> getDailyMerit({required DateTime date, String? classId});

  /// Upserts an exception row. If both flags are false, the row is removed
  /// instead (no row = both points earned, the default).
  Future<void> setException({
    required String studentId,
    required DateTime date,
    required bool missedRecessReturn,
    required bool leftEarly,
  });

  Future<void> addBonus({
    required String studentId,
    required DateTime date,
    required int points,
    String? reason,
  });

  Future<List<StudentPeriodSummary>> getStudentSummary({
    required DateTime from,
    required DateTime to,
    String? classId,
  });

  Future<List<ClassPeriodSummary>> getClassSummary({required DateTime from, required DateTime to});

  /// Logs an award. Returns false (no row written) if this exact
  /// category/scope/period was already logged -- enforced by a DB unique
  /// index, not just a client-side check, so it holds even under races.
  Future<bool> logAward({
    required MeritAwardCategory category,
    required String scopeType,
    String? studentId,
    String? classId,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? note,
  });

  Future<List<MeritAward>> getAwards({required DateTime periodStart, required DateTime periodEnd});
}
