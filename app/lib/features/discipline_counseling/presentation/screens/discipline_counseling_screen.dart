import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../settings/domain/entities/staff_profile.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../student/domain/entities/student.dart';
import '../../../student/presentation/providers/student_providers.dart';
import '../../../student/presentation/screens/student_detail_sheet.dart';
import '../../../student_portal/domain/entities/student_voice_submission.dart';
import '../../../student_portal/presentation/providers/student_portal_providers.dart';
import '../providers/discipline_counseling_providers.dart';

class DisciplineCounselingScreen extends ConsumerStatefulWidget {
  const DisciplineCounselingScreen({super.key});

  @override
  ConsumerState<DisciplineCounselingScreen> createState() => _DisciplineCounselingScreenState();
}

class _DisciplineCounselingScreenState extends ConsumerState<DisciplineCounselingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  String _disciplineStatus = '';
  String _counselingStatus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _hasAccess(StaffProfile? profile) {
    if (profile == null) return false;
    final role = profile.role.toLowerCase();
    return role == 'admin' || role == 'disiplin' || role == 'kaunselor';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const HomeBackButton(),
        title: const Text('Disiplin & Kaunseling (SSDOP/UBK)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.gavel), text: 'Kes Disiplin (SSDOP)'),
            Tab(icon: Icon(Icons.psychology), text: 'Sesi Kaunseling (UBK)'),
            Tab(icon: Icon(Icons.record_voice_over), text: 'Peti Suara Murid'),
            Tab(icon: Icon(Icons.analytics), text: 'Ringkasan & Analisis'),
          ],
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (!_hasAccess(profile)) {
            return _RestrictedAccessView(profile: profile);
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Cari nama murid, kelas, atau jenis kes...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openAddRecordDialog(context, profile!),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Rekod'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DisciplineTab(
                      searchQuery: _searchQuery,
                      statusFilter: _disciplineStatus,
                      onStatusChanged: (st) => setState(() => _disciplineStatus = st),
                    ),
                    _CounselingTab(
                      searchQuery: _searchQuery,
                      statusFilter: _counselingStatus,
                      onStatusChanged: (st) => setState(() => _counselingStatus = st),
                    ),
                    _StudentVoiceInboxTab(
                      searchQuery: _searchQuery,
                      profile: profile!,
                    ),
                    _AnalyticsTab(
                      searchQuery: _searchQuery,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Ralat memuatkan profil: $err')),
      ),
    );
  }

  void _openAddRecordDialog(BuildContext context, StaffProfile profile) {
    showDialog(
      context: context,
      builder: (_) => _AddRecordSelectionDialog(profile: profile),
    );
  }
}

class _RestrictedAccessView extends StatelessWidget {
  const _RestrictedAccessView({required this.profile});

  final StaffProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock, size: 64, color: Colors.amber.shade900),
            ),
            const SizedBox(height: 24),
            Text(
              'Akses Terhad (Restricted Access)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Modul ini khusus untuk Guru Disiplin, Guru Bimbingan & Kaunseling (UBK), dan Pentadbir (Admin) sekolah.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Chip(
              avatar: const Icon(Icons.person, size: 16),
              label: Text('Peranan Anda: ${(profile?.role ?? 'teacher').toUpperCase()}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisciplineTab extends ConsumerWidget {
  const _DisciplineTab({
    required this.searchQuery,
    required this.statusFilter,
    required this.onStatusChanged,
  });

  final String searchQuery;
  final String statusFilter;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(disciplineRecordsProvider((
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      studentId: null,
    )));

    final dateFormat = DateFormat('d MMM yyyy');

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Semua'),
                selected: statusFilter.isEmpty,
                onSelected: (_) => onStatusChanged(''),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Dalam Siasatan'),
                selected: statusFilter == 'dalam_siasatan',
                onSelected: (_) => onStatusChanged('dalam_siasatan'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Dirujuk UBK'),
                selected: statusFilter == 'dirujuk_ubk',
                onSelected: (_) => onStatusChanged('dirujuk_ubk'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Selesai'),
                selected: statusFilter == 'selesai',
                onSelected: (_) => onStatusChanged('selesai'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: listAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return const Center(child: Text('Tiada rekod disiplin ditemui.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final item = records[index];
                  final sevColor = switch (item.severity.toLowerCase()) {
                    'berat' => Colors.red,
                    'sederhana' => Colors.orange,
                    _ => Colors.blue,
                  };

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: sevColor.withValues(alpha: 0.15),
                      child: Text('${index + 1}', style: TextStyle(color: sevColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.studentName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sevColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sevColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            item.severity.toUpperCase(),
                            style: TextStyle(color: sevColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Kelas: ${item.className} • Kategori: ${item.category}'),
                        Text('Tindakan: ${item.actionTaken} • Tarikh: ${dateFormat.format(item.incidentDate)}'),
                        if (item.description != null && item.description!.isNotEmpty)
                          Text(
                            'Keterangan: ${item.description}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        Text(
                          'Pelapor: ${item.reporterName} • Status: ${item.status.replaceAll('_', ' ').toUpperCase()}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final student = await ref.read(studentRepositoryProvider).getById(item.studentId);
                      if (student != null && context.mounted) {
                        showStudentDetailSheet(context, student);
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Ralat memuatkan data: $err')),
          ),
        ),
      ],
    );
  }
}

class _CounselingTab extends ConsumerWidget {
  const _CounselingTab({
    required this.searchQuery,
    required this.statusFilter,
    required this.onStatusChanged,
  });

  final String searchQuery;
  final String statusFilter;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(counselingRecordsProvider((
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      studentId: null,
    )));

    final dateFormat = DateFormat('d MMM yyyy');

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Semua'),
                selected: statusFilter.isEmpty,
                onSelected: (_) => onStatusChanged(''),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Memerlukan Susulan'),
                selected: statusFilter == 'memerlukan_susulan',
                onSelected: (_) => onStatusChanged('memerlukan_susulan'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Selesai'),
                selected: statusFilter == 'selesai',
                onSelected: (_) => onStatusChanged('selesai'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: listAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return const Center(child: Text('Tiada sesi kaunseling ditemui.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final item = records[index];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Icon(Icons.psychology, color: Colors.purple.shade800),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.studentName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Text(
                            item.sessionType.toUpperCase(),
                            style: TextStyle(color: Colors.purple.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Kelas: ${item.className} • Bidang: ${item.focusArea.replaceAll('_', ' ').toUpperCase()}'),
                        Text('Tarikh Sesi: ${dateFormat.format(item.sessionDate)} • Kaunselor: ${item.counselorName}'),
                        if (item.outcomeNotes != null && item.outcomeNotes!.isNotEmpty)
                          Text(
                            'Nota Kaunselor: ${item.outcomeNotes}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        Text(
                          'Status Susulan: ${item.followUpStatus.replaceAll('_', ' ').toUpperCase()}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final student = await ref.read(studentRepositoryProvider).getById(item.studentId);
                      if (student != null && context.mounted) {
                        showStudentDetailSheet(context, student);
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Ralat memuatkan data: $err')),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(disciplineRecordsProvider((
      searchQuery: searchQuery,
      statusFilter: null,
      studentId: null,
    )));
    final counselingAsync = ref.watch(counselingRecordsProvider((
      searchQuery: searchQuery,
      statusFilter: null,
      studentId: null,
    )));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.gavel, size: 32, color: Colors.red),
                      const SizedBox(height: 8),
                      disciplineAsync.when(
                        data: (recs) => Text('${recs.length}', style: Theme.of(context).textTheme.headlineMedium),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, _) => const Text('0'),
                      ),
                      const Text('Jumlah Kes Disiplin'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.psychology, size: 32, color: Colors.purple),
                      const SizedBox(height: 8),
                      counselingAsync.when(
                        data: (recs) => Text('${recs.length}', style: Theme.of(context).textTheme.headlineMedium),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, _) => const Text('0'),
                      ),
                      const Text('Jumlah Sesi UBK'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddRecordSelectionDialog extends StatelessWidget {
  const _AddRecordSelectionDialog({required this.profile});

  final StaffProfile profile;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Pilih Jenis Rekod Untuk Ditambah'),
      children: [
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (_) => _AddDisciplineRecordDialog(profile: profile),
            );
          },
          child: const ListTile(
            leading: Icon(Icons.gavel, color: Colors.red),
            title: Text('Rekod Kes Disiplin (SSDOP)'),
            subtitle: Text('Salah laku, ponteng, kekemasan diri, amaran'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (_) => _AddCounselingRecordDialog(profile: profile),
            );
          },
          child: const ListTile(
            leading: Icon(Icons.psychology, color: Colors.purple),
            title: Text('Rekod Sesi Kaunseling (UBK)'),
            subtitle: Text('Sesi bimbingan & kaunseling individu / kelompok'),
          ),
        ),
      ],
    );
  }
}

class _AddDisciplineRecordDialog extends ConsumerStatefulWidget {
  const _AddDisciplineRecordDialog({required this.profile});

  final StaffProfile profile;

  @override
  ConsumerState<_AddDisciplineRecordDialog> createState() => _AddDisciplineRecordDialogState();
}

class _AddDisciplineRecordDialogState extends ConsumerState<_AddDisciplineRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  Student? _selectedStudent;
  DateTime _incidentDate = DateTime.now();
  String _category = 'Ponteng Sekolah/Kelas';
  String _severity = 'ringan';
  String _actionTaken = 'Nasihat / Amaran Lisan';
  String _status = 'dalam_siasatan';
  final _descController = TextEditingController();
  bool _saving = false;

  final _categories = const [
    'Ponteng Sekolah/Kelas',
    'Tingkah Laku Kurang Sopan',
    'Kekemasan Diri / Pakaian',
    'Buli / Gaduh',
    'Vandalism / Harta Benda',
    'Rokok / Vape',
    'Lain-lain',
  ];

  final _actions = const [
    'Nasihat / Amaran Lisan',
    'Surat Amaran 1',
    'Surat Amaran 2',
    'Surat Amaran 3',
    'Denda / Khidmat Masyarakat',
    'Gantung Sekolah',
    'Rujukan UBK',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Rekod Disiplin (SSDOP)'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StudentSelector(
                  onSelected: (student) => setState(() => _selectedStudent = student),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tarikh Kejadian'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_incidentDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _incidentDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _incidentDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Kategori Salah Laku'),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _severity,
                  decoration: const InputDecoration(labelText: 'Tahap Keseriusan'),
                  items: const [
                    DropdownMenuItem(value: 'ringan', child: Text('Ringan')),
                    DropdownMenuItem(value: 'sederhana', child: Text('Sederhana')),
                    DropdownMenuItem(value: 'berat', child: Text('Berat')),
                  ],
                  onChanged: (val) => setState(() => _severity = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _actionTaken,
                  decoration: const InputDecoration(labelText: 'Tindakan Diambil'),
                  items: _actions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (val) => setState(() => _actionTaken = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status Kes'),
                  items: const [
                    DropdownMenuItem(value: 'dalam_siasatan', child: Text('Dalam Siasatan')),
                    DropdownMenuItem(value: 'dirujuk_ubk', child: Text('Dirujuk UBK')),
                    DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                  ],
                  onChanged: (val) => setState(() => _status = val!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan Kes (Butiran)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving ? const CircularProgressIndicator() : const Text('Simpan Rekod'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila pilih murid.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(disciplineCounselingRepositoryProvider).addDisciplineRecord(
            studentId: _selectedStudent!.id,
            reporterId: widget.profile.id,
            incidentDate: _incidentDate,
            category: _category,
            severity: _severity,
            actionTaken: _actionTaken,
            status: _status,
            description: _descController.text.trim(),
          );

      ref.invalidate(disciplineRecordsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rekod disiplin berjaya disimpan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan rekod: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AddCounselingRecordDialog extends ConsumerStatefulWidget {
  const _AddCounselingRecordDialog({required this.profile});

  final StaffProfile profile;

  @override
  ConsumerState<_AddCounselingRecordDialog> createState() => _AddCounselingRecordDialogState();
}

class _AddCounselingRecordDialogState extends ConsumerState<_AddCounselingRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  Student? _selectedStudent;
  DateTime _sessionDate = DateTime.now();
  String _sessionType = 'individu';
  String _focusArea = 'sahsiah_disiplin';
  String _followUpStatus = 'memerlukan_susulan';
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Rekod Sesi Kaunseling (UBK)'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StudentSelector(
                  onSelected: (student) => setState(() => _selectedStudent = student),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tarikh Sesi'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_sessionDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _sessionDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _sessionDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sessionType,
                  decoration: const InputDecoration(labelText: 'Jenis Sesi'),
                  items: const [
                    DropdownMenuItem(value: 'individu', child: Text('Sesi Individu')),
                    DropdownMenuItem(value: 'kelompok', child: Text('Sesi Kelompok')),
                    DropdownMenuItem(value: 'ibu_bapa', child: Text('Sesi Bersama Ibu Bapa')),
                  ],
                  onChanged: (val) => setState(() => _sessionType = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _focusArea,
                  decoration: const InputDecoration(labelText: 'Bidang Fokus'),
                  items: const [
                    DropdownMenuItem(value: 'sahsiah_disiplin', child: Text('Sahsiah & Disiplin')),
                    DropdownMenuItem(value: 'akademik', child: Text('Peningkatan Akademik')),
                    DropdownMenuItem(value: 'kerjaya', child: Text('Bimbingan Kerjaya')),
                    DropdownMenuItem(value: 'psikososial', child: Text('Psikososial & Kesejahteraan Minda')),
                  ],
                  onChanged: (val) => setState(() => _focusArea = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _followUpStatus,
                  decoration: const InputDecoration(labelText: 'Status Susulan'),
                  items: const [
                    DropdownMenuItem(value: 'memerlukan_susulan', child: Text('Memerlukan Sesi Susulan')),
                    DropdownMenuItem(value: 'selesai', child: Text('Selesai / Kes Ditutup')),
                  ],
                  onChanged: (val) => setState(() => _followUpStatus = val!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Nota Sesi & Intervensi Kaunselor',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving ? const CircularProgressIndicator() : const Text('Simpan Sesi'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila pilih murid.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(disciplineCounselingRepositoryProvider).addCounselingRecord(
            studentId: _selectedStudent!.id,
            counselorId: widget.profile.id,
            sessionDate: _sessionDate,
            sessionType: _sessionType,
            focusArea: _focusArea,
            outcomeNotes: _notesController.text.trim(),
            followUpStatus: _followUpStatus,
          );

      ref.invalidate(counselingRecordsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rekod sesi kaunseling berjaya disimpan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan sesi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StudentSelector extends ConsumerStatefulWidget {
  const _StudentSelector({required this.onSelected});

  final ValueChanged<Student?> onSelected;

  @override
  ConsumerState<_StudentSelector> createState() => _StudentSelectorState();
}

class _StudentSelectorState extends ConsumerState<_StudentSelector> {
  Student? _selected;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selected != null) ...[
          InputChip(
            avatar: const CircleAvatar(child: Icon(Icons.person, size: 14)),
            label: Text('${_selected!.fullName} (${_selected!.className ?? 'Tiada Kelas'})'),
            onDeleted: () {
              setState(() => _selected = null);
              widget.onSelected(null);
            },
          ),
        ] else ...[
          TextField(
            decoration: const InputDecoration(
              labelText: 'Cari Nama Murid...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          if (_query.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: studentsAsync.when(
                data: (students) {
                  final filtered = students
                      .where((s) => s.fullName.toLowerCase().contains(_query) || (s.className?.toLowerCase().contains(_query) ?? false))
                      .take(5)
                      .toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Tiada murid dijumpai.'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final s = filtered[idx];
                      return ListTile(
                        dense: true,
                        title: Text(s.fullName),
                        subtitle: Text('Kelas: ${s.className ?? 'Tiada Kelas'}'),
                        onTap: () {
                          setState(() {
                            _selected = s;
                            _query = '';
                          });
                          widget.onSelected(s);
                        },
                      );
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Ralat: $e'),
              ),
            ),
        ],
      ],
    );
  }
}

class _StudentVoiceInboxTab extends ConsumerWidget {
  const _StudentVoiceInboxTab({required this.searchQuery, required this.profile});

  final String searchQuery;
  final StaffProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(allStudentVoiceSubmissionsProvider((statusFilter: null, categoryFilter: null)));
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return listAsync.when(
      data: (submissions) {
        final filtered = submissions.where((s) {
          if (searchQuery.trim().isEmpty) return true;
          final q = searchQuery.trim().toLowerCase();
          return s.subject.toLowerCase().contains(q) ||
              s.message.toLowerCase().contains(q) ||
              (s.studentName?.toLowerCase().contains(q) ?? false);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('Tiada hantaran Suara Murid ditemui.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final item = filtered[index];
            final statusColor = switch (item.status) {
              'selesai' => Colors.green,
              'dalam_tindakan' => Colors.orange,
              _ => Colors.blue,
            };

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: item.isAnonymous ? Colors.purple.shade100 : Colors.blue.shade100,
                child: Icon(item.isAnonymous ? Icons.visibility_off : Icons.person, color: item.isAnonymous ? Colors.purple.shade900 : Colors.blue.shade900),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(item.subject, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(item.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Murid: ${item.isAnonymous ? "SULIT / RAHSIA (ANONYMOUS)" : "${item.studentName ?? 'Murid'} (${item.className ?? '-'})"}'),
                  Text('Kategori: ${StudentVoiceSubmission.categoryLabel(item.category)}'),
                  Text('Mesej: ${item.message}'),
                  Text('Tarikh: ${dateFormat.format(item.createdAt)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  if (item.responseNotes != null && item.responseNotes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Maklum Balas Terakhir: ${item.responseNotes}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.green)),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.reply),
                tooltip: 'Maklum Balas / Kemaskini Status',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => _RespondVoiceDialog(submission: item, profile: profile),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Ralat: $err')),
    );
  }
}

class _RespondVoiceDialog extends ConsumerStatefulWidget {
  const _RespondVoiceDialog({required this.submission, required this.profile});

  final StudentVoiceSubmission submission;
  final StaffProfile profile;

  @override
  ConsumerState<_RespondVoiceDialog> createState() => _RespondVoiceDialogState();
}

class _RespondVoiceDialogState extends ConsumerState<_RespondVoiceDialog> {
  late String _status;
  final _responseController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.submission.status;
    _responseController.text = widget.submission.responseNotes ?? '';
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Maklum Balas Suara Murid'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perkara: ${widget.submission.subject}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Mesej: ${widget.submission.message}'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status Tindakan'),
              items: const [
                DropdownMenuItem(value: 'baru', child: Text('Baru Diterima')),
                DropdownMenuItem(value: 'dalam_tindakan', child: Text('Dalam Tindakan UBK / Disiplin')),
                DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _responseController,
              decoration: const InputDecoration(
                labelText: 'Nota Maklum Balas Kepada Murid',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving ? const CircularProgressIndicator() : const Text('Simpan Maklum Balas'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(studentPortalRepositoryProvider).respondToVoiceSubmission(
            submissionId: widget.submission.id,
            status: _status,
            responseNotes: _responseController.text.trim(),
            responderId: widget.profile.id,
          );

      ref.invalidate(allStudentVoiceSubmissionsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maklum balas berjaya disimpan.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
