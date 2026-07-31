import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/cutoff_time_row.dart';
import '../../domain/entities/school_settings.dart';
import '../../domain/entities/staff_profile.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

final schoolSettingsProvider = FutureProvider.autoDispose<SchoolSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).getSchoolSettings();
});

final cutoffTimesProvider = FutureProvider.autoDispose<List<CutoffTimeRow>>((ref) {
  return ref.watch(settingsRepositoryProvider).getCutoffTimes();
});

final staffListProvider = FutureProvider.autoDispose<List<StaffProfile>>((ref) {
  return ref.watch(settingsRepositoryProvider).getStaff();
});

/// The signed-in user's own profile. Used only for client-side "you're not
/// an admin" UI gating -- RLS and fn_upsert_staff_by_email's own internal
/// check are the actual enforcement.
final currentProfileProvider = FutureProvider.autoDispose<StaffProfile?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;
  final row = await client.from('profiles').select('id, full_name, role').eq('id', userId).maybeSingle();
  return row == null ? null : StaffProfile.fromMap(row);
});
