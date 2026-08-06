import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../student/domain/entities/enrollment_status.dart';
import '../../../student/presentation/screens/student_detail_sheet.dart' show colorForEnrollmentStatus;
import '../../domain/entities/parent_portal_data.dart';
import '../providers/parent_portal_providers.dart';

Color _colorForAttendanceStatus(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.hadir:
      return Colors.green;
    case AttendanceStatus.lewat:
      return Colors.orange;
    case AttendanceStatus.tidakHadir:
      return Colors.red;
    case AttendanceStatus.cutiSakit:
      return Colors.blue;
    case AttendanceStatus.urusanRasmi:
      return Colors.purple;
  }
}

class ParentPortalScreen extends ConsumerWidget {
  const ParentPortalScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(parentPortalDataProvider(token));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset('assets/images/crest.png', width: 28, height: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('DARE TO CHANGE (D2C)', overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ],
        ),
      ),
      body: dataAsync.when(
        data: (data) {
          if (data == null) {
            return const _PortalMessage(
              icon: Icons.link_off,
              message: "This link isn't valid anymore. Please ask the school for a new one.",
            );
          }
          return ParentPortalBody(data: data);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _PortalMessage(icon: Icons.error_outline, message: 'Failed to load: $error'),
      ),
    );
  }
}

class _PortalMessage extends StatelessWidget {
  const _PortalMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ParentPortalBody extends StatelessWidget {
  const ParentPortalBody({super.key, required this.data});

  final ParentPortalData data;

  @override
  Widget build(BuildContext context) {
    final notActive = data.enrollmentStatus != EnrollmentStatus.active;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(data.studentFullName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(data.className ?? 'No class', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        if (notActive) ...[
          const SizedBox(height: 12),
          Card(
            color: colorForEnrollmentStatus(data.enrollmentStatus).withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorForEnrollmentStatus(data.enrollmentStatus)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.enrollmentStatus.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (data.enrollmentStatusDate != null)
                          Text(
                            'Effective ${DateFormat('d MMM yyyy').format(data.enrollmentStatusDate!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (data.enrollmentStatusReason != null && data.enrollmentStatusReason!.isNotEmpty)
                          Text(data.enrollmentStatusReason!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.fact_check,
                color: Colors.green,
                label: 'Attendance This Week',
                value: '${data.attendanceWeekRate.toStringAsFixed(0)}%',
                sub: '${data.attendanceWeekPresent}/${data.attendanceWeekTotal} days',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month,
                color: Colors.blue,
                label: 'Attendance This Month',
                value: '${data.attendanceMonthRate.toStringAsFixed(0)}%',
                sub: '${data.attendanceMonthPresent}/${data.attendanceMonthTotal} days',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.star,
          color: Colors.purple,
          label: 'Merit This Month',
          value: '${data.meritTotalPoints} / ${data.meritMaxPoints} pts',
          sub: '${data.meritRate.toStringAsFixed(0)}% of max, over ${data.meritDaysRecorded} recorded days',
        ),
        const SizedBox(height: 20),
        Text('Recent Attendance', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (data.attendanceRecent.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No attendance recorded yet.'))
        else
          Card(
            child: Column(
              children: [
                for (final day in data.attendanceRecent)
                  ListTile(
                    dense: true,
                    title: Text(DateFormat('EEEE, d MMM yyyy').format(day.date)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _colorForAttendanceStatus(day.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        day.status.label,
                        style: TextStyle(color: _colorForAttendanceStatus(day.status), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.color, required this.label, required this.value, required this.sub});

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(sub, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
