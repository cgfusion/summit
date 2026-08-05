import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/enrollment_status.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/student_guardian.dart';
import '../providers/student_providers.dart';

Color colorForEnrollmentStatus(EnrollmentStatus status) {
  switch (status) {
    case EnrollmentStatus.active:
      return Colors.green;
    case EnrollmentStatus.suspended:
      return Colors.orange;
    case EnrollmentStatus.expelled:
      return Colors.red;
    case EnrollmentStatus.transferredOut:
      return Colors.blue;
    case EnrollmentStatus.withdrawn:
      return Colors.brown;
    case EnrollmentStatus.deceased:
      return Colors.blueGrey;
    case EnrollmentStatus.graduated:
      return Colors.purple;
  }
}

Future<void> showStudentDetailSheet(BuildContext context, Student student) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _StudentDetailSheet(student: student),
  );
}

class _StudentDetailSheet extends ConsumerWidget {
  const _StudentDetailSheet({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardiansAsync = ref.watch(studentGuardiansProvider(student.id));
    final statusColor = colorForEnrollmentStatus(student.enrollmentStatus);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(student.fullName, style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            Text(
              '${student.className ?? 'No class'} • ID ${student.studentId}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text('Enrollment Status', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: statusColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(student.enrollmentStatus.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (student.enrollmentStatusDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Effective ${DateFormat('d MMM yyyy').format(student.enrollmentStatusDate!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (student.enrollmentStatusReason != null && student.enrollmentStatusReason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(student.enrollmentStatusReason!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Change Status'),
                        onPressed: () => _showChangeStatusDialog(context, ref, student),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Parent / Guardian',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: const Text('Add'),
                  onPressed: () => _showGuardianFormDialog(context, ref, studentId: student.id),
                ),
              ],
            ),
            guardiansAsync.when(
              data: (guardians) {
                if (guardians.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No parent/guardian contacts recorded yet.'),
                  );
                }
                return Column(
                  children: [
                    for (final guardian in guardians) _GuardianCard(guardian: guardian, student: student),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Text('Failed to load: $error'),
            ),
          ],
        );
      },
    );
  }
}

class _GuardianCard extends ConsumerWidget {
  const _GuardianCard({required this.guardian, required this.student});

  final StudentGuardian guardian;
  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        title: Row(
          children: [
            Flexible(child: Text(guardian.fullName)),
            if (guardian.isPrimary) ...[
              const SizedBox(width: 6),
              const Chip(label: Text('Primary'), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            ],
            if (guardian.isEmergencyContact) ...[
              const SizedBox(width: 6),
              Chip(
                label: const Text('Emergency'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.red.withValues(alpha: 0.12),
              ),
            ],
          ],
        ),
        subtitle: Text(
          [
            if (guardian.relationship != null && guardian.relationship!.isNotEmpty) guardian.relationship,
            if (guardian.phone != null && guardian.phone!.isNotEmpty) guardian.phone,
            if (guardian.email != null && guardian.email!.isNotEmpty) guardian.email,
            if (guardian.icNumber != null && guardian.icNumber!.isNotEmpty) 'IC ${guardian.icNumber}',
          ].join(' • '),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showGuardianFormDialog(context, ref, studentId: student.id, existing: guardian);
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Remove this contact?'),
                  content: Text('${guardian.fullName} will be removed from ${student.fullName}\'s guardian list.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(studentRepositoryProvider).deleteGuardian(guardian.id);
                ref.invalidate(studentGuardiansProvider(student.id));
              }
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Remove')),
          ],
        ),
      ),
    );
  }
}

void _showChangeStatusDialog(BuildContext context, WidgetRef ref, Student student) {
  var status = student.enrollmentStatus;
  var effectiveDate = student.enrollmentStatusDate ?? DateTime.now();
  final reasonController = TextEditingController(text: student.enrollmentStatusReason ?? '');
  String? errorText;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Change Enrollment Status'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<EnrollmentStatus>(
                initialValue: status,
                items: [
                  for (final s in EnrollmentStatus.values) DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (value) => setDialogState(() => status = value ?? status),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: effectiveDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setDialogState(() => effectiveDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Effective date'),
                  child: Text(DateFormat('d MMM yyyy').format(effectiveDate)),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(errorText!, style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(studentRepositoryProvider).updateEnrollmentStatus(
                      studentId: student.id,
                      status: status,
                      reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                      effectiveDate: effectiveDate,
                    );
                ref.invalidate(studentsProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) Navigator.pop(context);
              } catch (error) {
                setDialogState(() => errorText = 'Failed to update: $error');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

void _showGuardianFormDialog(
  BuildContext context,
  WidgetRef ref, {
  required String studentId,
  StudentGuardian? existing,
}) {
  final nameController = TextEditingController(text: existing?.fullName ?? '');
  final relationshipController = TextEditingController(text: existing?.relationship ?? '');
  final icNumberController = TextEditingController(text: existing?.icNumber ?? '');
  final phoneController = TextEditingController(text: existing?.phone ?? '');
  final emailController = TextEditingController(text: existing?.email ?? '');
  var isPrimary = existing?.isPrimary ?? false;
  var isEmergencyContact = existing?.isEmergencyContact ?? false;
  String? errorText;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Parent / Guardian' : 'Edit Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 8),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(labelText: 'Relationship (e.g. Bapa, Ibu, Penjaga)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: icNumberController,
                decoration: const InputDecoration(labelText: 'IC number (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Primary contact'),
                value: isPrimary,
                onChanged: (value) => setDialogState(() => isPrimary = value ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Emergency contact'),
                value: isEmergencyContact,
                onChanged: (value) => setDialogState(() => isEmergencyContact = value ?? false),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                setDialogState(() => errorText = 'Full name is required.');
                return;
              }
              try {
                final repository = ref.read(studentRepositoryProvider);
                if (existing == null) {
                  await repository.addGuardian(
                    studentId: studentId,
                    fullName: nameController.text.trim(),
                    relationship: relationshipController.text.trim().isEmpty ? null : relationshipController.text.trim(),
                    icNumber: icNumberController.text.trim().isEmpty ? null : icNumberController.text.trim(),
                    phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                    isPrimary: isPrimary,
                    isEmergencyContact: isEmergencyContact,
                  );
                } else {
                  await repository.updateGuardian(
                    guardianId: existing.id,
                    fullName: nameController.text.trim(),
                    relationship: relationshipController.text.trim().isEmpty ? null : relationshipController.text.trim(),
                    icNumber: icNumberController.text.trim().isEmpty ? null : icNumberController.text.trim(),
                    phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                    isPrimary: isPrimary,
                    isEmergencyContact: isEmergencyContact,
                  );
                }
                ref.invalidate(studentGuardiansProvider(studentId));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (error) {
                setDialogState(() => errorText = 'Failed to save: $error');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
