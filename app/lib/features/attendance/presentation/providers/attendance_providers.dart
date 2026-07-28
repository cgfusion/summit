import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

final attendanceDateFilterProvider = StateProvider<DateTime>((ref) => DateTime.now());

final attendanceClassFilterProvider = StateProvider<String?>((ref) => null);

final attendanceForDateProvider = FutureProvider.autoDispose<List<AttendanceDay>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final date = ref.watch(attendanceDateFilterProvider);
  final classId = ref.watch(attendanceClassFilterProvider);
  return repository.getAttendanceForDate(date: date, classId: classId);
});
