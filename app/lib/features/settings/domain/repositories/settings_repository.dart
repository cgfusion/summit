import '../entities/cutoff_time_row.dart';
import '../entities/school_settings.dart';
import '../entities/staff_profile.dart';

abstract interface class SettingsRepository {
  Future<SchoolSettings> getSchoolSettings();

  Future<void> updateProgramPeriod({required DateTime start, required DateTime end});

  Future<void> updateMeritSettings({
    required bool enableHadir,
    required bool enableTepatMasa,
    required bool enableKembaliRehat,
    required bool enableKekalSesi,
    required bool enableBonus,
    required int maxPoints,
  });

  Future<List<CutoffTimeRow>> getCutoffTimes();

  Future<void> updateCutoffTime({required String session, required int dayOfWeek, required String cutoffTime});

  Future<List<StaffProfile>> getStaff();

  /// Looks up an existing Supabase Auth account by email (server-side, via
  /// `fn_upsert_staff_by_email`) and grants/updates their staff role. Fails
  /// if no account exists for that email -- they must sign up first.
  Future<void> upsertStaffByEmail({required String email, required String fullName, required String role});

  Future<void> updateStaffRole({required String profileId, required String role});

  /// Revokes app access (deletes the profiles row). Does not delete their
  /// underlying Supabase Auth login.
  Future<void> removeStaff({required String profileId});
}
