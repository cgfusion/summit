import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/value_objects/date_range.dart';
import '../providers/merit_providers.dart';
import 'period_picker.dart';

class MeritClassSummaryScreen extends ConsumerStatefulWidget {
  const MeritClassSummaryScreen({super.key});

  @override
  ConsumerState<MeritClassSummaryScreen> createState() => _MeritClassSummaryScreenState();
}

class _MeritClassSummaryScreenState extends ConsumerState<MeritClassSummaryScreen> {
  late DateRange _range = thisWeekRange();

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(classPeriodSummaryProvider(_range));

    return Scaffold(
      appBar: AppBar(title: const Text('Class Merit Summary')),
      body: Column(
        children: [
          PeriodPicker(range: _range, onChanged: (range) => setState(() => _range = range)),
          Expanded(
            child: summaryAsync.when(
              data: (classes) {
                if (classes.isEmpty) {
                  return const Center(child: Text('No merit records for this period yet.'));
                }
                final sorted = [...classes]..sort((a, b) => b.pct.compareTo(a.pct));
                return ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = sorted[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(c.className),
                      subtitle: Text(
                        '${c.totalPoints}/${c.maxPoints} pts · Transisi terlepas: ${c.missedRecessReturnRate.toStringAsFixed(1)}%',
                      ),
                      trailing: Text('${c.pct.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleMedium),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Failed to load class summary: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
