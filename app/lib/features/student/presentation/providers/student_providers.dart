import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/student_guardian.dart';
import '../../domain/repositories/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

final studentSearchQueryProvider = StateProvider<String>((ref) => '');

final studentClassFilterProvider = StateProvider<String?>((ref) => null);

/// Off by default -- the Students screen only shows active students unless
/// this is toggled on, matching every other roster in the app.
final studentIncludeInactiveProvider = StateProvider<bool>((ref) => false);

final studentsProvider = FutureProvider.autoDispose<List<Student>>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  final classId = ref.watch(studentClassFilterProvider);
  final searchQuery = ref.watch(studentSearchQueryProvider);
  final includeInactive = ref.watch(studentIncludeInactiveProvider);
  return repository.getStudents(classId: classId, searchQuery: searchQuery, activeOnly: !includeInactive);
});

final studentGuardiansProvider = FutureProvider.autoDispose.family<List<StudentGuardian>, String>((ref, studentId) {
  return ref.watch(studentRepositoryProvider).getGuardians(studentId);
});
