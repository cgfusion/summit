import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/parent_portal_providers.dart';
import 'parent_portal_screen.dart';

class ParentIcLookupScreen extends ConsumerStatefulWidget {
  const ParentIcLookupScreen({super.key});

  @override
  ConsumerState<ParentIcLookupScreen> createState() => _ParentIcLookupScreenState();
}

class _ParentIcLookupScreenState extends ConsumerState<ParentIcLookupScreen> {
  final _parentIcController = TextEditingController();
  final _childIcController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ParentIcLookupParams? _activeParams;
  int _selectedStudentIndex = 0;

  @override
  void dispose() {
    _parentIcController.dispose();
    _childIcController.dispose();
    super.dispose();
  }

  void _submit() {
    final parentIc = _parentIcController.text.trim();
    if (parentIc.isEmpty) return;

    final childIc = _childIcController.text.trim();
    setState(() {
      _activeParams = (
        parentIc: parentIc,
        childIc: childIc.isEmpty ? null : childIc,
      );
      _selectedStudentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset('assets/images/crest.png', width: 28, height: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('DARE TO CHANGE — PARENT PORTAL', overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semakan Status Murid (Ibu Bapa / Penjaga)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masukkan Nombor Kad Pengenalan untuk melihat status kehadiran dan merit anak-anak jagaan anda.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _parentIcController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'No. KP Ibu Bapa / Penjaga (Parent IC)',
                        hintText: 'e.g. 820315-12-5432',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _childIcController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'No. KP Anak / MyKid (Pilihan / Optional)',
                        hintText: 'e.g. 100412-12-6543',
                        prefixIcon: Icon(Icons.face_outlined),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.search),
                        label: const Text('Semak Status / Check Status'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_activeParams != null) ...[
            _ResultsSection(
              params: _activeParams!,
              selectedIndex: _selectedStudentIndex,
              onSelectStudent: (index) => setState(() => _selectedStudentIndex = index),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultsSection extends ConsumerWidget {
  const _ResultsSection({
    required this.params,
    required this.selectedIndex,
    required this.onSelectStudent,
  });

  final ParentIcLookupParams params;
  final int selectedIndex;
  final ValueChanged<int> onSelectStudent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(parentPortalDataByIcProvider(params));

    return resultsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Tiada rekod murid ditemui untuk No. KP tersebut.\nSila pastikan nombor adalah betul atau hubungi pihak sekolah.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (students.length > 1) ...[
              Text(
                'Murid di bawah jagaan anda (${students.length} Orang):',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < students.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${students[i].studentFullName} (${students[i].className ?? 'Tiada Kelas'})'),
                          selected: selectedIndex == i,
                          onSelected: (selected) {
                            if (selected) onSelectStudent(i);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ParentPortalBody(
              data: students[selectedIndex < students.length ? selectedIndex : 0],
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Ralat / Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
