/// How a period's absence days split between unexplained (tidak_hadir) and
/// the two excused-leave types.
class LeaveTypeBreakdown {
  const LeaveTypeBreakdown({
    required this.tidakHadirCount,
    required this.cutiSakitCount,
    required this.urusanRasmiCount,
  });

  final int tidakHadirCount;
  final int cutiSakitCount;
  final int urusanRasmiCount;

  int get total => tidakHadirCount + cutiSakitCount + urusanRasmiCount;

  factory LeaveTypeBreakdown.fromMap(Map<String, dynamic> map) {
    return LeaveTypeBreakdown(
      tidakHadirCount: (map['tidak_hadir_count'] as num).toInt(),
      cutiSakitCount: (map['cuti_sakit_count'] as num).toInt(),
      urusanRasmiCount: (map['urusan_rasmi_count'] as num).toInt(),
    );
  }
}
