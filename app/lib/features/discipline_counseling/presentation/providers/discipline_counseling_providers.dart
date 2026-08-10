import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/discipline_counseling_repository_impl.dart';
import '../../domain/entities/counseling_record.dart';
import '../../domain/entities/discipline_record.dart';
import '../../domain/repositories/discipline_counseling_repository.dart';

final disciplineCounselingRepositoryProvider = Provider<DisciplineCounselingRepository>((ref) {
  return DisciplineCounselingRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

typedef DisciplineFilterQuery = ({String? searchQuery, String? statusFilter, String? studentId});

final disciplineRecordsProvider = FutureProvider.autoDispose
    .family<List<DisciplineRecord>, DisciplineFilterQuery>((ref, query) {
  return ref.watch(disciplineCounselingRepositoryProvider).getDisciplineRecords(
        searchQuery: query.searchQuery,
        statusFilter: query.statusFilter,
        studentId: query.studentId,
      );
});

typedef CounselingFilterQuery = ({String? searchQuery, String? statusFilter, String? studentId});

final counselingRecordsProvider = FutureProvider.autoDispose
    .family<List<CounselingRecord>, CounselingFilterQuery>((ref, query) {
  return ref.watch(disciplineCounselingRepositoryProvider).getCounselingRecords(
        searchQuery: query.searchQuery,
        statusFilter: query.statusFilter,
        studentId: query.studentId,
      );
});

final studentDisciplineSummaryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, studentId) {
  return ref.watch(disciplineCounselingRepositoryProvider).getStudentDisciplineSummary(studentId);
});
