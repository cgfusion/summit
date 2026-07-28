import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/merit_repository_impl.dart';
import '../../domain/entities/class_period_summary.dart';
import '../../domain/entities/merit_day.dart';
import '../../domain/entities/student_period_summary.dart';
import '../../domain/repositories/merit_repository.dart';
import '../../domain/value_objects/date_range.dart';

final meritRepositoryProvider = Provider<MeritRepository>((ref) {
  return MeritRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

final meritDateFilterProvider = StateProvider<DateTime>((ref) => DateTime.now());

final meritClassFilterProvider = StateProvider<String?>((ref) => null);

final dailyMeritProvider = FutureProvider.autoDispose<List<MeritDay>>((ref) {
  final repository = ref.watch(meritRepositoryProvider);
  final date = ref.watch(meritDateFilterProvider);
  final classId = ref.watch(meritClassFilterProvider);
  return repository.getDailyMerit(date: date, classId: classId);
});

final programPeriodProvider = FutureProvider.autoDispose<DateRange>((ref) {
  return ref.watch(meritRepositoryProvider).getProgramPeriod();
});

final studentPeriodSummaryProvider =
    FutureProvider.autoDispose.family<List<StudentPeriodSummary>, DateRange>((ref, range) {
  final repository = ref.watch(meritRepositoryProvider);
  return repository.getStudentSummary(from: range.from, to: range.to);
});

final classPeriodSummaryProvider = FutureProvider.autoDispose.family<List<ClassPeriodSummary>, DateRange>((ref, range) {
  final repository = ref.watch(meritRepositoryProvider);
  return repository.getClassSummary(from: range.from, to: range.to);
});
