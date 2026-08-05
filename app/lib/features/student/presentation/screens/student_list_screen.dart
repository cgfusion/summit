import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../class_management/presentation/providers/class_providers.dart';
import '../../domain/entities/enrollment_status.dart';
import '../providers/student_providers.dart';
import 'student_detail_sheet.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    final classesAsync = ref.watch(classesProvider);
    final selectedClassId = ref.watch(studentClassFilterProvider);
    final includeInactive = ref.watch(studentIncludeInactiveProvider);

    return Scaffold(
      appBar: AppBar(leading: const HomeBackButton(), title: const Text('Students')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => ref.read(studentSearchQueryProvider.notifier).state = value,
                  ),
                ),
                const SizedBox(width: 12),
                classesAsync.when(
                  data: (classes) => DropdownMenu<String?>(
                    label: const Text('Class'),
                    initialSelection: selectedClassId,
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(value: null, label: 'All classes'),
                      ...classes.map((c) => DropdownMenuEntry(value: c.id, label: c.name)),
                    ],
                    onSelected: (value) => ref.read(studentClassFilterProvider.notifier).state = value,
                  ),
                  loading: () => const SizedBox(width: 160, child: LinearProgressIndicator()),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Checkbox(
                  value: includeInactive,
                  onChanged: (value) => ref.read(studentIncludeInactiveProvider.notifier).state = value ?? false,
                ),
                const Text('Show suspended / expelled / transferred / etc.'),
              ],
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }
                return ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final notActive = student.enrollmentStatus != EnrollmentStatus.active;
                    return ListTile(
                      onTap: () => showStudentDetailSheet(context, student),
                      title: Row(
                        children: [
                          Flexible(child: Text(student.fullName)),
                          if (notActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorForEnrollmentStatus(student.enrollmentStatus).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                student.enrollmentStatus.shortLabel,
                                style: TextStyle(
                                  color: colorForEnrollmentStatus(student.enrollmentStatus),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text('${student.className ?? '-'} • ID ${student.studentId}'),
                      trailing: Text(student.gender ?? ''),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Failed to load students: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
