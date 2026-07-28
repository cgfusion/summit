import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/class_repository_impl.dart';
import '../../domain/entities/school_class.dart';
import '../../domain/repositories/class_repository.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

final classesProvider = FutureProvider.autoDispose<List<SchoolClass>>((ref) {
  return ref.watch(classRepositoryProvider).getClasses();
});
