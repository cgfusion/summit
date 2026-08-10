import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/student_portal_repository_impl.dart';
import '../../domain/entities/student_portal_data.dart';
import '../../domain/entities/student_voice_submission.dart';
import '../../domain/repositories/student_portal_repository.dart';

final studentPortalRepositoryProvider = Provider<StudentPortalRepository>((ref) {
  return StudentPortalRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

final studentPortalDataProvider = FutureProvider.autoDispose
    .family<StudentPortalData?, String>((ref, qrToken) {
  return ref.watch(studentPortalRepositoryProvider).getStudentPortalDataByQr(qrToken);
});

typedef VoiceFilterQuery = ({String? statusFilter, String? categoryFilter});

final allStudentVoiceSubmissionsProvider = FutureProvider.autoDispose
    .family<List<StudentVoiceSubmission>, VoiceFilterQuery>((ref, query) {
  return ref.watch(studentPortalRepositoryProvider).getAllVoiceSubmissions(
        statusFilter: query.statusFilter,
        categoryFilter: query.categoryFilter,
      );
});
