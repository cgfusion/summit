import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../student/presentation/providers/student_providers.dart';
import '../providers/class_providers.dart';

class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      body: classesAsync.when(
        data: (classes) => ListView.separated(
          itemCount: classes.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final schoolClass = classes[index];
            return ListTile(
              title: Text(schoolClass.name),
              subtitle: Text('Form ${schoolClass.formLevel} • ${schoolClass.homeroomTeacherName ?? 'No teacher assigned'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.read(studentClassFilterProvider.notifier).state = schoolClass.id;
                context.push('/students');
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load classes: $error')),
      ),
    );
  }
}
