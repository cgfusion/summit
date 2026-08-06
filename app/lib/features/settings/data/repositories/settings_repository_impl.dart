import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/cutoff_time_row.dart';
import '../../domain/entities/school_settings.dart';
import '../../domain/entities/staff_profile.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<SchoolSettings> getSchoolSettings() async {
    final row = await _client
        .from('attendance_settings')
        .select('program_start_date, program_end_date, school_timezone, merit_enable_hadir, '
            'merit_enable_tepat_masa, merit_enable_kembali_rehat, merit_enable_kekal_sesi, '
            'merit_enable_bonus, merit_max_points')
        .eq('id', 1)
        .single();
    return SchoolSettings.fromMap(row);
  }

  @override
  Future<void> updateProgramPeriod({required DateTime start, required DateTime end}) async {
    await _client
        .from('attendance_settings')
        .update({'program_start_date': formatDateOnly(start), 'program_end_date': formatDateOnly(end)})
        .eq('id', 1);
  }

  @override
  Future<void> updateMeritSettings({
    required bool enableHadir,
    required bool enableTepatMasa,
    required bool enableKembaliRehat,
    required bool enableKekalSesi,
    required bool enableBonus,
    required int maxPoints,
  }) async {
    await _client.from('attendance_settings').update({
      'merit_enable_hadir': enableHadir,
      'merit_enable_tepat_masa': enableTepatMasa,
      'merit_enable_kembali_rehat': enableKembaliRehat,
      'merit_enable_kekal_sesi': enableKekalSesi,
      'merit_enable_bonus': enableBonus,
      'merit_max_points': maxPoints,
    }).eq('id', 1);
  }

  @override
  Future<List<CutoffTimeRow>> getCutoffTimes() async {
    final rows = await _client.from('session_cutoff_times').select().order('session').order('day_of_week');
    return rows.map((row) => CutoffTimeRow.fromMap(row)).toList();
  }

  @override
  Future<void> updateCutoffTime({required String session, required int dayOfWeek, required String cutoffTime}) async {
    await _client
        .from('session_cutoff_times')
        .update({'cutoff_time': cutoffTime})
        .eq('session', session)
        .eq('day_of_week', dayOfWeek);
  }

  @override
  Future<List<StaffProfile>> getStaff() async {
    final rows = await _client.from('profiles').select('id, full_name, role').order('full_name');
    return rows.map((row) => StaffProfile.fromMap(row)).toList();
  }

  @override
  Future<void> upsertStaffByEmail({required String email, required String fullName, required String role}) async {
    await _client.rpc('fn_upsert_staff_by_email', params: {
      'p_email': email,
      'p_full_name': fullName,
      'p_role': role,
    });
  }

  @override
  Future<void> updateStaffRole({required String profileId, required String role}) async {
    await _client.from('profiles').update({'role': role}).eq('id', profileId);
  }

  @override
  Future<void> removeStaff({required String profileId}) async {
    await _client.from('profiles').delete().eq('id', profileId);
  }
}
