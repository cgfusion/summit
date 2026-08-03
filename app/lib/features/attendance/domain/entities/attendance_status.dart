enum AttendanceStatus {
  hadir,
  lewat,
  tidakHadir,
  cutiSakit,
  urusanRasmi;

  static AttendanceStatus fromDb(String value) {
    switch (value) {
      case 'hadir':
        return AttendanceStatus.hadir;
      case 'lewat':
        return AttendanceStatus.lewat;
      case 'tidak_hadir':
        return AttendanceStatus.tidakHadir;
      case 'cuti_sakit':
        return AttendanceStatus.cutiSakit;
      case 'urusan_rasmi':
        return AttendanceStatus.urusanRasmi;
      default:
        throw ArgumentError('Unknown attendance status: $value');
    }
  }

  String get dbValue {
    switch (this) {
      case AttendanceStatus.hadir:
        return 'hadir';
      case AttendanceStatus.lewat:
        return 'lewat';
      case AttendanceStatus.tidakHadir:
        return 'tidak_hadir';
      case AttendanceStatus.cutiSakit:
        return 'cuti_sakit';
      case AttendanceStatus.urusanRasmi:
        return 'urusan_rasmi';
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.hadir:
        return 'Hadir';
      case AttendanceStatus.lewat:
        return 'Lewat';
      case AttendanceStatus.tidakHadir:
        return 'Tidak Hadir';
      case AttendanceStatus.cutiSakit:
        return 'Cuti Sakit';
      case AttendanceStatus.urusanRasmi:
        return 'Urusan Rasmi';
    }
  }
}
