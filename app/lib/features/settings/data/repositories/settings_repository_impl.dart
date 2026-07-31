import 'package:supabase_flutter/supabase_flutter.dart';

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
        .select('program_start_date, program_end_date, school_timezone')
        .eq('id', 1)
        .single();
    return SchoolSettings.fromMap(row);
  }

  @override
  Future<void> updateProgramPeriod({required DateTime start, required DateTime end}) async {
    await _client
        .from('attendance_settings')
        .update({'program_start_date': _dateOnly(start), 'program_end_date': _dateOnly(end)})
        .eq('id', 1);
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

  String _dateOnly(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }
}
