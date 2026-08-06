/// Utility functions for consistent date manipulation and formatting across the app.
library;

/// Returns a copy of [dateTime] with the time component (hour, minute, second, etc.) stripped to midnight 00:00:00.
DateTime dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

/// Formats a [DateTime] into a standard ISO-8601 date string (`YYYY-MM-DD`).
String formatDateOnly(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
