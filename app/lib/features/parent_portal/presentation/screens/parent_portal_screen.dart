import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../student/domain/entities/enrollment_status.dart';
import '../../../student/presentation/screens/student_detail_sheet.dart' show colorForEnrollmentStatus;
import '../../domain/entities/parent_portal_data.dart';
import '../providers/parent_portal_providers.dart';
import 'package:app/core/widgets/full_screen_image_viewer.dart';
import 'package:app/features/discipline_counseling/domain/entities/sudut_info_post.dart';
import 'package:app/features/discipline_counseling/presentation/providers/discipline_counseling_providers.dart';

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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ParentPortalBody(data: data),
          );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        const SizedBox(height: 20),
        Consumer(
          builder: (context, ref, _) {
            final postsAsync = ref.watch(activeSudutInfoPostsProvider((category: null, audience: 'ibu_bapa')));
            return postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.blue.shade800),
                        const SizedBox(width: 6),
                        Text('Sudut Info', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final post in posts) ParentSudutInfoCard(post: post),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}

class ParentSudutInfoCard extends StatelessWidget {
  const ParentSudutInfoCard({super.key, required this.post});

  final SudutInfoPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Text(post.category.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            const SizedBox(height: 8),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              SudutInfoImage(imageUrl: post.imageUrl!),
              const SizedBox(height: 8),
            ],
            Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(post.content, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              'Pengendali: ${post.managedBy}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
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
