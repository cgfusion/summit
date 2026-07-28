import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/value_objects/date_range.dart';

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateRange thisWeekRange({DateTime? now}) {
  final today = _startOfDay(now ?? DateTime.now());
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  return (from: monday, to: sunday);
}

DateRange lastWeekRange({DateTime? now}) {
  final week = thisWeekRange(now: now);
  return (from: week.from.subtract(const Duration(days: 7)), to: week.to.subtract(const Duration(days: 7)));
}

DateRange thisMonthRange({DateTime? now}) {
  final today = _startOfDay(now ?? DateTime.now());
  final first = DateTime(today.year, today.month, 1);
  final lastDay = DateTime(today.year, today.month + 1, 0);
  return (from: first, to: lastDay);
}

/// Row of period presets (this week / last week / this month) plus a custom
/// range picker, used by the class-summary and rewards screens.
class PeriodPicker extends StatelessWidget {
  const PeriodPicker({super.key, required this.range, required this.onChanged});

  final DateRange range;
  final ValueChanged<DateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('d MMM');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ChoiceChip(label: const Text('This week'), selected: range == thisWeekRange(), onSelected: (_) => onChanged(thisWeekRange())),
          ChoiceChip(label: const Text('Last week'), selected: range == lastWeekRange(), onSelected: (_) => onChanged(lastWeekRange())),
          ChoiceChip(label: const Text('This month'), selected: range == thisMonthRange(), onSelected: (_) => onChanged(thisMonthRange())),
          ActionChip(
            avatar: const Icon(Icons.date_range, size: 16),
            label: Text('${format.format(range.from)} – ${format.format(range.to)}'),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
                initialDateRange: DateTimeRange(start: range.from, end: range.to),
              );
              if (picked != null) {
                onChanged((from: picked.start, to: picked.end));
              }
            },
          ),
        ],
      ),
    );
  }
}
