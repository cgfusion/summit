import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

final studentSearchQueryProvider = StateProvider<String>((ref) => '');

final studentClassFilterProvider = StateProvider<String?>((ref) => null);

final studentsProvider = FutureProvider.autoDispose<List<Student>>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  final classId = ref.watch(studentClassFilterProvider);
  final searchQuery = ref.watch(studentSearchQueryProvider);
  return repository.getStudents(classId: classId, searchQuery: searchQuery);
});
