class CutoffTimeRow {
  const CutoffTimeRow({
    required this.session,
    required this.dayOfWeek,
    required this.cutoffTime,
  });

  final String session;
  final int dayOfWeek;

  /// Raw 'HH:MM:SS' text as stored/returned by Postgres.
  final String cutoffTime;

  factory CutoffTimeRow.fromMap(Map<String, dynamic> map) {
    return CutoffTimeRow(
      session: map['session'] as String,
      dayOfWeek: (map['day_of_week'] as num).toInt(),
      cutoffTime: map['cutoff_time'] as String,
    );
  }
}
