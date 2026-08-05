/// A student's current standing at the school -- distinct from
/// [Student.studyStatus], which is the raw MOE "STATUS PENGAJIAN" import
/// field. Non-active students are excluded from current rosters
/// (attendance-taking, merit, leaderboards) but keep their historical
/// records.
enum EnrollmentStatus {
  active,
  suspended,
  expelled,
  transferredOut,
  withdrawn,
  deceased,
  graduated;

  static EnrollmentStatus fromDb(String value) {
    switch (value) {
      case 'active':
        return EnrollmentStatus.active;
      case 'suspended':
        return EnrollmentStatus.suspended;
      case 'expelled':
        return EnrollmentStatus.expelled;
      case 'transferred_out':
        return EnrollmentStatus.transferredOut;
      case 'withdrawn':
        return EnrollmentStatus.withdrawn;
      case 'deceased':
        return EnrollmentStatus.deceased;
      case 'graduated':
        return EnrollmentStatus.graduated;
      default:
        throw ArgumentError('Unknown enrollment status: $value');
    }
  }

  String get dbValue {
    switch (this) {
      case EnrollmentStatus.active:
        return 'active';
      case EnrollmentStatus.suspended:
        return 'suspended';
      case EnrollmentStatus.expelled:
        return 'expelled';
      case EnrollmentStatus.transferredOut:
        return 'transferred_out';
      case EnrollmentStatus.withdrawn:
        return 'withdrawn';
      case EnrollmentStatus.deceased:
        return 'deceased';
      case EnrollmentStatus.graduated:
        return 'graduated';
    }
  }

  /// "English / Malay (MOE standard)".
  String get label {
    switch (this) {
      case EnrollmentStatus.active:
        return 'Active / Aktif';
      case EnrollmentStatus.suspended:
        return 'Suspended / Digantung Sekolah';
      case EnrollmentStatus.expelled:
        return 'Expelled / Dibuang Sekolah';
      case EnrollmentStatus.transferredOut:
        return 'Transferred Out / Bertukar Sekolah';
      case EnrollmentStatus.withdrawn:
        return 'Withdrawn / Berhenti Sekolah';
      case EnrollmentStatus.deceased:
        return 'Deceased / Meninggal Dunia';
      case EnrollmentStatus.graduated:
        return 'Graduated / Tamat Persekolahan';
    }
  }

  /// Short form for compact spaces (badges, chips).
  String get shortLabel {
    switch (this) {
      case EnrollmentStatus.active:
        return 'Active';
      case EnrollmentStatus.suspended:
        return 'Suspended';
      case EnrollmentStatus.expelled:
        return 'Expelled';
      case EnrollmentStatus.transferredOut:
        return 'Transferred';
      case EnrollmentStatus.withdrawn:
        return 'Withdrawn';
      case EnrollmentStatus.deceased:
        return 'Deceased';
      case EnrollmentStatus.graduated:
        return 'Graduated';
    }
  }
}
