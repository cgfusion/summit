/// Present/late/absent/mc counts (+ merit points, rewards issued) for one
/// calendar day. Used both for "today" and "yesterday" to compute deltas.
class AttendanceDaySummary {
  const AttendanceDaySummary({
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.mcCount,
    required this.recordedCount,
    required this.meritPoints,
    required this.rewardsIssued,
  });

  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int mcCount;
  final int recordedCount;
  final int meritPoints;
  final int rewardsIssued;

  static const zero = AttendanceDaySummary(
    presentCount: 0,
    lateCount: 0,
    absentCount: 0,
    mcCount: 0,
    recordedCount: 0,
    meritPoints: 0,
    rewardsIssued: 0,
  );

  factory AttendanceDaySummary.fromMap(Map<String, dynamic> map) {
    return AttendanceDaySummary(
      presentCount: (map['present_count'] as num).toInt(),
      lateCount: (map['late_count'] as num).toInt(),
      absentCount: (map['absent_count'] as num).toInt(),
      mcCount: (map['mc_count'] as num).toInt(),
      recordedCount: (map['recorded_count'] as num).toInt(),
      meritPoints: (map['merit_points'] as num).toInt(),
      rewardsIssued: (map['rewards_issued'] as num).toInt(),
    );
  }
}

/// One school day's attendance breakdown -- powers both the weekly trend
/// line and the monthly heatmap.
class AttendanceTrendPoint {
  const AttendanceTrendPoint({
    required this.schoolDate,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.mcCount,
    required this.recordedCount,
    required this.attendanceRate,
  });

  final DateTime schoolDate;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int mcCount;
  final int recordedCount;
  final double attendanceRate;

  factory AttendanceTrendPoint.fromMap(Map<String, dynamic> map) {
    return AttendanceTrendPoint(
      schoolDate: DateTime.parse(map['school_date'] as String),
      presentCount: (map['present_count'] as num).toInt(),
      lateCount: (map['late_count'] as num).toInt(),
      absentCount: (map['absent_count'] as num).toInt(),
      mcCount: (map['mc_count'] as num).toInt(),
      recordedCount: (map['recorded_count'] as num).toInt(),
      attendanceRate: (map['attendance_rate'] as num).toDouble(),
    );
  }
}

class MeritTrendPoint {
  const MeritTrendPoint({required this.schoolDate, required this.totalPoints});

  final DateTime schoolDate;
  final int totalPoints;

  factory MeritTrendPoint.fromMap(Map<String, dynamic> map) {
    return MeritTrendPoint(
      schoolDate: DateTime.parse(map['school_date'] as String),
      totalPoints: (map['total_points'] as num).toInt(),
    );
  }
}

class ClassAttendanceRow {
  const ClassAttendanceRow({
    required this.classId,
    required this.className,
    required this.recordedCount,
    required this.attendanceRate,
  });

  final String classId;
  final String className;
  final int recordedCount;
  final double attendanceRate;

  factory ClassAttendanceRow.fromMap(Map<String, dynamic> map) {
    return ClassAttendanceRow(
      classId: map['class_id'] as String,
      className: map['class_name'] as String,
      recordedCount: (map['recorded_count'] as num).toInt(),
      attendanceRate: (map['attendance_rate'] as num).toDouble(),
    );
  }
}

class StudentStreak {
  const StudentStreak({
    required this.studentId,
    required this.fullName,
    required this.classId,
    required this.streakDays,
  });

  final String studentId;
  final String fullName;
  final String? classId;
  final int streakDays;

  factory StudentStreak.fromMap(Map<String, dynamic> map) {
    return StudentStreak(
      studentId: map['student_id'] as String,
      fullName: map['full_name'] as String,
      classId: map['class_id'] as String?,
      streakDays: (map['streak_days'] as num).toInt(),
    );
  }
}

enum ActivityKind { scan, manualAttendance, meritAward }

class RecentActivityItem {
  const RecentActivityItem({
    required this.kind,
    required this.occurredAt,
    required this.studentName,
    required this.className,
    required this.detail,
  });

  final ActivityKind kind;
  final DateTime occurredAt;
  final String? studentName;
  final String? className;
  final String detail;

  factory RecentActivityItem.fromMap(Map<String, dynamic> map) {
    final kind = switch (map['kind'] as String) {
      'scan' => ActivityKind.scan,
      'manual_attendance' => ActivityKind.manualAttendance,
      'merit_award' => ActivityKind.meritAward,
      _ => ActivityKind.scan,
    };
    return RecentActivityItem(
      kind: kind,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      studentName: map['student_name'] as String?,
      className: map['class_name'] as String?,
      detail: map['detail'] as String,
    );
  }
}

/// Attendance rate, average merit %, and "discipline" rate (share of
/// present-days with none of the 3 exception flags set) over a period.
class KpiOverview {
  const KpiOverview({required this.attendanceRate, required this.meritAvgPct, required this.disciplineRate});

  final double attendanceRate;
  final double meritAvgPct;
  final double disciplineRate;

  factory KpiOverview.fromMap(Map<String, dynamic> map) {
    return KpiOverview(
      attendanceRate: (map['attendance_rate'] as num).toDouble(),
      meritAvgPct: (map['merit_avg_pct'] as num).toDouble(),
      disciplineRate: (map['discipline_rate'] as num).toDouble(),
    );
  }
}
