import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/services.dart';
import '../../../../core/layout/app_shell.dart';
import '../../../../core/widgets/rich_text_toolbar_widget.dart';
import '../../../reports/presentation/screens/whatsapp_report_section.dart' show AttachStudentDialog;
import '../../../settings/domain/entities/staff_profile.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../student/domain/entities/student.dart';
import '../../../student/presentation/providers/student_providers.dart';
import '../../../student/presentation/screens/student_detail_sheet.dart';
import '../../../student_portal/domain/entities/student_voice_submission.dart';
import '../../../student_portal/presentation/providers/student_portal_providers.dart';
import 'package:app/features/discipline_counseling/domain/entities/school_announcement.dart';
import 'package:app/features/discipline_counseling/domain/entities/sudut_info_post.dart';
import 'package:app/features/discipline_counseling/presentation/providers/discipline_counseling_providers.dart';

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
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _hasAccess(StaffProfile? profile) {
    if (profile == null) return false;
    final r = profile.role.toLowerCase();
    return r == 'admin' || r == 'disiplin' || r == 'kaunselor' || r == 'guru';
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
            Tab(icon: Icon(Icons.info_outline), text: 'Sudut Info'),
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
                    _SudutInfoTab(
                      profile: profile,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _AnnouncementComposerWidget(
            category: 'disiplin',
            title: 'Special Announcement (Discipline)',
            color: Colors.amber.shade900,
          ),
        ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _AnnouncementComposerWidget(
            category: 'kaunseling',
            title: 'Special Announcement (Kaunseling UBK)',
            color: Colors.purple.shade700,
          ),
        ),
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

class _AnnouncementComposerWidget extends ConsumerStatefulWidget {
  const _AnnouncementComposerWidget({
    required this.category,
    required this.title,
    required this.color,
  });

  final String category; // 'disiplin' or 'kaunseling'
  final String title;
  final Color color;

  @override
  ConsumerState<_AnnouncementComposerWidget> createState() => _AnnouncementComposerWidgetState();
}

class _AnnouncementComposerWidgetState extends ConsumerState<_AnnouncementComposerWidget> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  Student? _attachedStudent;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _attachStudent() async {
    final student = await showDialog<Student>(
      context: context,
      builder: (dialogContext) => const AttachStudentDialog(),
    );
    if (student != null) {
      setState(() => _attachedStudent = student);
    }
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila isi tajuk dan kandungan pengumuman.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final profile = ref.read(currentProfileProvider).value;
      await ref.read(disciplineCounselingRepositoryProvider).createSchoolAnnouncement(
            category: widget.category,
            title: title,
            content: body,
            authorId: profile?.id,
            targetStudentId: _attachedStudent?.id,
          );

      if (mounted) {
        _titleController.clear();
        _bodyController.clear();
        setState(() => _attachedStudent = null);
        ref.invalidate(schoolAnnouncementsProvider(widget.category));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengumuman ${widget.category == 'disiplin' ? 'Disiplin' : 'Kaunseling'} berjaya diterbitkan ke Portal Murid!'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerbitkan pengumuman: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _togglePublish(SchoolAnnouncement ann) async {
    final newStatus = !ann.isPublished;
    try {
      await ref.read(disciplineCounselingRepositoryProvider).toggleAnnouncementPublishedStatus(
            id: ann.id,
            isPublished: newStatus,
          );
      ref.invalidate(allSchoolAnnouncementsProvider(widget.category));
      ref.invalidate(schoolAnnouncementsProvider(widget.category));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? 'Pengumuman telah diterbitkan ke Portal Murid.'
                : 'Pengumuman telah dinyahterbitkan (disembunyikan daripada Portal Murid).'),
            backgroundColor: newStatus ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }

  Future<void> _deleteAnnouncement(SchoolAnnouncement ann) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Padam Pengumuman?'),
        content: Text('Adakah anda pasti mahu memadam pengumuman "${ann.title}" secara kekal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('PADAM'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(disciplineCounselingRepositoryProvider).deleteSchoolAnnouncement(ann.id);
        ref.invalidate(allSchoolAnnouncementsProvider(widget.category));
        ref.invalidate(schoolAnnouncementsProvider(widget.category));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengumuman berjaya dipadam.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memadam pengumuman: $e'), backgroundColor: Colors.red.shade800),
          );
        }
      }
    }
  }

  Future<void> _openEditDialog(SchoolAnnouncement ann) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EditAnnouncementDialog(announcement: ann),
    );
    if (result == true) {
      ref.invalidate(allSchoolAnnouncementsProvider(widget.category));
      ref.invalidate(schoolAnnouncementsProvider(widget.category));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAnnouncementsAsync = ref.watch(allSchoolAnnouncementsProvider(widget.category));
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: widget.color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: widget.color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.color),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Siaran Portal Murid',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pengumuman ini akan dipaparkan secara langsung di Tab Pengumuman Portal Murid.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tajuk Pengumuman',
                hintText: 'Contoh: Peringatan Sahsiah / Sesi Motivasi Bimbingan',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            RichTextToolbarWidget(controller: _bodyController),
            TextField(
              controller: _bodyController,
              minLines: 8,
              maxLines: 15,
              decoration: const InputDecoration(
                labelText: 'Kandungan Pengumuman',
                hintText: 'Taip kandungan pengumuman di sini...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_search, size: 18),
                  label: Text(_attachedStudent == null
                      ? 'Lampirkan Murid (Pilihan)'
                      : 'Murid: ${_attachedStudent!.fullName} (${_attachedStudent!.className ?? '-'})'),
                  onPressed: _attachStudent,
                ),
                if (_attachedStudent != null) ...[
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _attachedStudent = null),
                  ),
                ],
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Salin WA'),
                  onPressed: (_titleController.text.trim().isEmpty && _bodyController.text.trim().isEmpty)
                      ? null
                      : () async {
                          final text = '📢 *${_titleController.text.trim()}*\n\n${_bodyController.text.trim()}${_attachedStudent != null ? '\n\nMurid: ${_attachedStudent!.fullName} (${_attachedStudent!.className ?? '-'})' : ''}';
                          await Clipboard.setData(ClipboardData(text: text));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Teks disalin ke papan klip untuk WhatsApp!')),
                            );
                          }
                        },
                ),
                ElevatedButton.icon(
                  icon: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, size: 16),
                  label: const Text('TERBITKAN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submitting ? null : _publish,
                ),
              ],
            ),
            const Divider(height: 32),

            // MANAGEMENT SECTION: SENARAI PENGUMUMAN (EDIT, DELETE, UNPUBLISH)
            allAnnouncementsAsync.when(
              data: (announcements) {
                if (announcements.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Tiada rekod pengumuman sebelum ini.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    tilePadding: EdgeInsets.zero,
                    leading: Icon(Icons.list_alt, color: widget.color),
                    title: Text(
                      'Senarai Pengumuman (${announcements.length})',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: widget.color),
                    ),
                    subtitle: const Text('Uruskan pengumuman: Edit, Padam, atau Nyahterbit daripada Portal Murid', style: TextStyle(fontSize: 11)),
                    children: announcements.map((ann) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: ann.isPublished ? widget.color.withValues(alpha: 0.3) : Colors.grey.shade400,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // PUBLISHED STATUS BADGE
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: ann.isPublished
                                          ? Colors.green.shade100
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: ann.isPublished ? Colors.green.shade700 : Colors.grey.shade600,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          ann.isPublished ? Icons.visibility : Icons.visibility_off,
                                          size: 12,
                                          color: ann.isPublished ? Colors.green.shade900 : Colors.grey.shade800,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          ann.isPublished ? 'DITERBITKAN (LIVE)' : 'NYAHTERBIT / DRAF',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: ann.isPublished ? Colors.green.shade900 : Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    dateFormat.format(ann.createdAt),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(ann.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(ann.content, style: const TextStyle(fontSize: 13, height: 1.4)),
                              if (ann.targetStudentName != null && ann.targetStudentName!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Murid Terlibat: ${ann.targetStudentName}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                ),
                              ],
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Penulis: ${ann.authorName ?? "Staf Sekolah"}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                  ),
                                  const Spacer(),
                                  // TOGGLE PUBLISH BUTTON
                                  TextButton.icon(
                                    icon: Icon(
                                      ann.isPublished ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 16,
                                      color: ann.isPublished ? Colors.orange.shade800 : Colors.green.shade800,
                                    ),
                                    label: Text(
                                      ann.isPublished ? 'Nyahterbit' : 'Terbit',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ann.isPublished ? Colors.orange.shade800 : Colors.green.shade800,
                                      ),
                                    ),
                                    onPressed: () => _togglePublish(ann),
                                  ),
                                  // EDIT BUTTON
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                    tooltip: 'Edit Pengumuman',
                                    onPressed: () => _openEditDialog(ann),
                                  ),
                                  // DELETE BUTTON
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    tooltip: 'Padam Pengumuman',
                                    onPressed: () => _deleteAnnouncement(ann),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator())),
              error: (err, _) => Text('Gagal memuatkan senarai pengumuman: $err', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditAnnouncementDialog extends ConsumerStatefulWidget {
  const _EditAnnouncementDialog({required this.announcement});

  final SchoolAnnouncement announcement;

  @override
  ConsumerState<_EditAnnouncementDialog> createState() => _EditAnnouncementDialogState();
}

class _EditAnnouncementDialogState extends ConsumerState<_EditAnnouncementDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late bool _isPublished;
  Student? _attachedStudent;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _contentController = TextEditingController(text: widget.announcement.content);
    _isPublished = widget.announcement.isPublished;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _attachStudent() async {
    final student = await showDialog<Student>(
      context: context,
      builder: (dialogContext) => const AttachStudentDialog(),
    );
    if (student != null) {
      setState(() => _attachedStudent = student);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tajuk dan kandungan tidak boleh dibiarkan kosong.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(disciplineCounselingRepositoryProvider).updateSchoolAnnouncement(
            id: widget.announcement.id,
            title: title,
            content: content,
            targetStudentId: _attachedStudent?.id ?? widget.announcement.targetStudentId,
            isPublished: _isPublished,
          );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengumuman berjaya dikemaskini!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengemaskini: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDiscipline = widget.announcement.category.toLowerCase() == 'disiplin';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit_note, color: isDiscipline ? Colors.amber.shade900 : Colors.purple.shade700),
          const SizedBox(width: 8),
          const Expanded(child: Text('Edit Pengumuman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tajuk Pengumuman',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 8,
              maxLines: 15,
              decoration: const InputDecoration(
                labelText: 'Kandungan Pengumuman',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_search, size: 16),
                  label: Text(_attachedStudent != null
                      ? 'Murid: ${_attachedStudent!.fullName}'
                      : widget.announcement.targetStudentName != null
                          ? 'Murid: ${widget.announcement.targetStudentName}'
                          : 'Lampirkan Murid (Pilihan)'),
                  onPressed: _attachStudent,
                ),
                if (_attachedStudent != null) ...[
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _attachedStudent = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Status Penerbitan (Live di Portal)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text(_isPublished ? 'Terbit di Portal Murid' : 'Nyahterbit (Disembunyikan)'),
              value: _isPublished,
              onChanged: (val) => setState(() => _isPublished = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('BATAL'),
        ),
        ElevatedButton.icon(
          icon: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save, size: 16),
          label: const Text('SIMPAN'),
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _SudutInfoTab extends ConsumerStatefulWidget {
  const _SudutInfoTab({required this.profile});
  final StaffProfile profile;

  @override
  ConsumerState<_SudutInfoTab> createState() => _SudutInfoTabState();
}

class _SudutInfoTabState extends ConsumerState<_SudutInfoTab> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _managedByController = TextEditingController(text: 'Unit Disiplin & Kaunseling');
  String _selectedCategory = 'disiplin';
  DateTime _validFrom = DateTime.now();
  DateTime? _validUntil;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _managedByController.dispose();
    super.dispose();
  }

  bool _uploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();

      setState(() => _uploadingImage = true);

      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      final fileName = 'sudut_info_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final supabase = Supabase.instance.client;

      await supabase.storage.from('sudut-info-banners').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      final publicUrl = supabase.storage.from('sudut-info-banners').getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          _imageUrlController.text = publicUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gambar poster berjaya dimuat naik ke Supabase Storage!'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat naik gambar: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickDateTime({required bool isValidFrom}) async {
    final initialDate = isValidFrom ? _validFrom : (_validUntil ?? DateTime.now().add(const Duration(days: 7)));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isValidFrom) {
        _validFrom = selected;
      } else {
        _validUntil = selected;
      }
    });
  }

  Future<void> _createPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila isi tajuk dan kandungan Sudut Info.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(disciplineCounselingRepositoryProvider).createSudutInfoPost(
            category: _selectedCategory,
            title: title,
            content: content,
            imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
            managedBy: _managedByController.text.trim().isEmpty ? 'Unit Disiplin & Kaunseling' : _managedByController.text.trim(),
            authorId: widget.profile.id,
            validFrom: _validFrom,
            validUntil: _validUntil,
          );

      if (mounted) {
        _titleController.clear();
        _contentController.clear();
        _imageUrlController.clear();
        setState(() {
          _validFrom = DateTime.now();
          _validUntil = null;
        });
        ref.invalidate(allSudutInfoPostsProvider(null));
        ref.invalidate(activeSudutInfoPostsProvider(null));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sudut Info (beserta Grafik Poster) berjaya diterbitkan!'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerbitkan Sudut Info: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _togglePublishStatus(SudutInfoPost post) async {
    final newStatus = !post.isPublished;
    try {
      await ref.read(disciplineCounselingRepositoryProvider).toggleSudutInfoPublishStatus(
            id: post.id,
            isPublished: newStatus,
          );
      ref.invalidate(allSudutInfoPostsProvider(null));
      ref.invalidate(activeSudutInfoPostsProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? 'Sudut Info telah diterbitkan secara Live.'
                : 'Sudut Info telah dinyahterbitkan (disembunyikan).'),
            backgroundColor: newStatus ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }

  Future<void> _deleteStorageImage(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final trimmed = url.trim();
    if (trimmed.contains('sudut-info-banners/')) {
      final fileName = trimmed.split('sudut-info-banners/').last.split('?').first;
      if (fileName.isNotEmpty) {
        try {
          await Supabase.instance.client.storage
              .from('sudut-info-banners')
              .remove([fileName]);
        } catch (_) {}
      }
    }
  }

  Future<void> _deletePost(SudutInfoPost post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Padam Sudut Info?'),
        content: Text('Adakah anda pasti mahu memadam info "${post.title}" secara kekal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('PADAM'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(disciplineCounselingRepositoryProvider).deleteSudutInfoPost(post.id);
        await _deleteStorageImage(post.imageUrl);
        ref.invalidate(allSudutInfoPostsProvider(null));
        ref.invalidate(activeSudutInfoPostsProvider(null));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sudut Info berjaya dipadam.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memadam: $e'), backgroundColor: Colors.red.shade800),
          );
        }
      }
    }
  }

  Future<void> _openEditDialog(SudutInfoPost post) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EditSudutInfoDialog(post: post),
    );
    if (result == true) {
      ref.invalidate(allSudutInfoPostsProvider(null));
      ref.invalidate(activeSudutInfoPostsProvider(null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPostsAsync = ref.watch(allSudutInfoPostsProvider(null));
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COMPOSER CARD
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.blue.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade800, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Tambah Info Baharu Ke Sudut Info',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pengumuman Sudut Info akan dipaparkan pada Halaman Utama (Landing Page) & Portal Murid mengikut tempoh masa yang ditetapkan.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategori Info',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'disiplin', child: Text('📢 Pengumuman Disiplin')),
                            DropdownMenuItem(value: 'kaunseling', child: Text('💜 Bimbingan & Kaunseling (UBK)')),
                            DropdownMenuItem(value: 'sahsiah', child: Text('🌟 Pengiktirafan Sahsiah')),
                            DropdownMenuItem(value: 'sekolah', child: Text('🏫 Hebahan Sekolah')),
                            DropdownMenuItem(value: 'umum', child: Text('ℹ️ Info Umum')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _managedByController,
                          decoration: const InputDecoration(
                            labelText: 'Unit / Agensi Pengendali',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tajuk Sudut Info',
                      hintText: 'Contoh: Kempen Sahsiah Terpuji / Minggu Kaunseling UBK',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // POSTER / BANNER GRAPHIC SECTION
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.image, size: 18, color: Colors.purple.shade900),
                            const SizedBox(width: 6),
                            Text(
                              'Grafik Poster & Banner (Pilihan Guru / Kaunselor)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple.shade900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _imageUrlController,
                                decoration: InputDecoration(
                                  labelText: 'Pautan Gambar Poster / Banner (URL)',
                                  hintText: 'Tampal pautan poster (Canva, Drive, Supabase, dsb.)',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixIcon: _imageUrlController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          tooltip: 'Buang Gambar',
                                          onPressed: () async {
                                            final currentUrl = _imageUrlController.text;
                                            _imageUrlController.clear();
                                            setState(() {});
                                            await _deleteStorageImage(currentUrl);
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: _uploadingImage
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.upload_file, size: 16),
                              label: const Text('Muat Naik Fail'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              onPressed: _uploadingImage ? null : _pickAndUploadImage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Templat Grafik D2C (Tekan untuk Pilih):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.school, size: 14),
                              label: const Text('Bangunan SMK Sungai Damit', style: TextStyle(fontSize: 10)),
                              onPressed: () => setState(() => _imageUrlController.text = 'assets/images/school_front.jpg'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.psychology, size: 14),
                              label: const Text('Poster Kaunseling UBK', style: TextStyle(fontSize: 10)),
                              onPressed: () => setState(() => _imageUrlController.text = 'https://images.unsplash.com/photo-1577896851231-70ef18881754?auto=format&fit=crop&w=800&q=80'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.gavel, size: 14),
                              label: const Text('Banner Disiplin & Sahsiah', style: TextStyle(fontSize: 10)),
                              onPressed: () => setState(() => _imageUrlController.text = 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=800&q=80'),
                            ),
                          ],
                        ),
                        if (_imageUrlController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _imageUrlController.text.startsWith('assets/')
                                ? Image.asset(_imageUrlController.text, height: 120, width: double.infinity, fit: BoxFit.cover)
                                : Image.network(
                                    _imageUrlController.text.trim(),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Text('Pratonton Gambar Tidak Tersedia', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // HTML FORMATTING TOOLBAR
                  RichTextToolbarWidget(controller: _contentController),
                  TextField(
                    controller: _contentController,
                    minLines: 8,
                    maxLines: 16,
                    decoration: const InputDecoration(
                      labelText: 'Kandungan Sudut Info (Format HTML/Teks)',
                      hintText: 'Gunakan butang di atas untuk memasukkan teks Tebal, Condong, Garis Bawah, Bullet, Nombor...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TEMPOH MASA PAPARAN (VALIDITY PERIOD)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 18, color: Colors.blue.shade900),
                            const SizedBox(width: 6),
                            Text(
                              'Tetapan Tempoh Paparan (Masa Mula & Masa Tamat)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.event, size: 16),
                              label: Text('Masa Mula: ${dateFormat.format(_validFrom)}'),
                              onPressed: () => _pickDateTime(isValidFrom: true),
                            ),
                            OutlinedButton.icon(
                              icon: Icon(Icons.event_busy, size: 16, color: _validUntil == null ? Colors.grey : Colors.red.shade700),
                              label: Text(_validUntil == null
                                  ? 'Masa Tamat: Selamanya (Tiada Tamat)'
                                  : 'Masa Tamat: ${dateFormat.format(_validUntil!)}'),
                              onPressed: () => _pickDateTime(isValidFrom: false),
                            ),
                            if (_validUntil != null) ...[
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                                tooltip: 'Buang Tarikh Tamat (Paparkan Selamanya)',
                                onPressed: () => setState(() => _validUntil = null),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: _submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: const Text('TERBITKAN KE SUDUT INFO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _submitting ? null : _createPost,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // SENARAI PENGURUSAN SUDUT INFO
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.blue.shade900, size: 22),
              const SizedBox(width: 8),
              Text(
                'Senarai Pengurusan Sudut Info',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Muat Semula',
                onPressed: () {
                  ref.invalidate(allSudutInfoPostsProvider(null));
                  ref.invalidate(activeSudutInfoPostsProvider(null));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          allPostsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Tiada pos Sudut Info ditemui. Sila tambah info baharu di atas.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final statusColor = post.statusColor;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  post.statusLabel,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  post.category.toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                dateFormat.format(post.createdAt),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: post.imageUrl!.startsWith('assets/')
                                  ? Image.asset(post.imageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover)
                                  : Image.network(
                                      post.imageUrl!,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                    ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            post.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post.content,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 14, color: Colors.black54),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Paparan: ${dateFormat.format(post.validFrom)}  ➜  ${post.validUntil == null ? "Selamanya (Tiada Tamat)" : dateFormat.format(post.validUntil!)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Pengendali: ${post.managedBy} (${post.authorName ?? "Staf"})',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                icon: Icon(
                                  post.isPublished ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 16,
                                  color: post.isPublished ? Colors.orange.shade800 : Colors.green.shade800,
                                ),
                                label: Text(
                                  post.isPublished ? 'Nyahterbit' : 'Terbit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: post.isPublished ? Colors.orange.shade800 : Colors.green.shade800,
                                  ),
                                ),
                                onPressed: () => _togglePublishStatus(post),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                tooltip: 'Edit Sudut Info',
                                onPressed: () => _openEditDialog(post),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                tooltip: 'Padam Sudut Info',
                                onPressed: () => _deletePost(post),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (err, _) => Text('Gagal memuatkan Sudut Info: $err', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EditSudutInfoDialog extends ConsumerStatefulWidget {
  const _EditSudutInfoDialog({required this.post});
  final SudutInfoPost post;

  @override
  ConsumerState<_EditSudutInfoDialog> createState() => _EditSudutInfoDialogState();
}

class _EditSudutInfoDialogState extends ConsumerState<_EditSudutInfoDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _managedByController;
  late String _category;
  late bool _isPublished;
  late DateTime _validFrom;
  DateTime? _validUntil;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _imageUrlController = TextEditingController(text: widget.post.imageUrl ?? '');
    _managedByController = TextEditingController(text: widget.post.managedBy);
    _category = widget.post.category;
    _isPublished = widget.post.isPublished;
    _validFrom = widget.post.validFrom;
    _validUntil = widget.post.validUntil;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _managedByController.dispose();
    super.dispose();
  }

  bool _uploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();

      setState(() => _uploadingImage = true);

      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      final fileName = 'sudut_info_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final supabase = Supabase.instance.client;

      await supabase.storage.from('sudut-info-banners').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      final publicUrl = supabase.storage.from('sudut-info-banners').getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          _imageUrlController.text = publicUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gambar poster berjaya dimuat naik ke Supabase Storage!'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat naik gambar: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickDateTime({required bool isValidFrom}) async {
    final initialDate = isValidFrom ? _validFrom : (_validUntil ?? DateTime.now().add(const Duration(days: 7)));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isValidFrom) {
        _validFrom = selected;
      } else {
        _validUntil = selected;
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tajuk dan kandungan tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(disciplineCounselingRepositoryProvider).updateSudutInfoPost(
            id: widget.post.id,
            category: _category,
            title: title,
            content: content,
            imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
            managedBy: _managedByController.text.trim().isEmpty ? 'Unit Disiplin & Kaunseling' : _managedByController.text.trim(),
            validFrom: _validFrom,
            validUntil: _validUntil,
            isPublished: _isPublished,
          );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sudut Info berjaya dikemaskini!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengemaskini: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteStorageImage(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final trimmed = url.trim();
    if (trimmed.contains('sudut-info-banners/')) {
      final fileName = trimmed.split('sudut-info-banners/').last.split('?').first;
      if (fileName.isNotEmpty) {
        try {
          await Supabase.instance.client.storage
              .from('sudut-info-banners')
              .remove([fileName]);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(child: Text('Edit Sudut Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'disiplin', child: Text('Disiplin')),
                      DropdownMenuItem(value: 'kaunseling', child: Text('Kaunseling UBK')),
                      DropdownMenuItem(value: 'sahsiah', child: Text('Sahsiah')),
                      DropdownMenuItem(value: 'sekolah', child: Text('Sekolah')),
                      DropdownMenuItem(value: 'umum', child: Text('Umum')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _managedByController,
                    decoration: const InputDecoration(labelText: 'Pengendali', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tajuk Info', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Pautan Gambar Poster / Banner (URL)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _imageUrlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              tooltip: 'Buang Gambar',
                              onPressed: () async {
                                final currentUrl = _imageUrlController.text;
                                _imageUrlController.clear();
                                setState(() {});
                                await _deleteStorageImage(currentUrl);
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: _uploadingImage
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_file, size: 16),
                  label: const Text('Muat Naik'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  onPressed: _uploadingImage ? null : _pickAndUploadImage,
                ),
              ],
            ),
            if (_imageUrlController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _imageUrlController.text.startsWith('assets/')
                    ? Image.asset(_imageUrlController.text, height: 100, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(
                        _imageUrlController.text.trim(),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
              ),
            ],
            const SizedBox(height: 12),
            RichTextToolbarWidget(controller: _contentController),
            TextField(
              controller: _contentController,
              minLines: 8,
              maxLines: 15,
              decoration: const InputDecoration(labelText: 'Kandungan Info', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const Text('Tempoh Masa Paparan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              icon: const Icon(Icons.event, size: 16),
              label: Text('Masa Mula: ${dateFormat.format(_validFrom)}'),
              onPressed: () => _pickDateTime(isValidFrom: true),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.event_busy, size: 16, color: _validUntil == null ? Colors.grey : Colors.red),
                    label: Text(_validUntil == null ? 'Tamat: Selamanya' : 'Tamat: ${dateFormat.format(_validUntil!)}'),
                    onPressed: () => _pickDateTime(isValidFrom: false),
                  ),
                ),
                if (_validUntil != null) ...[
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                    onPressed: () => setState(() => _validUntil = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Status Penerbitan (Live)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text(_isPublished ? 'Terbit secara Live' : 'Nyahterbit (Disembunyikan)'),
              value: _isPublished,
              onChanged: (val) => setState(() => _isPublished = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('BATAL')),
        ElevatedButton.icon(
          icon: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save, size: 16),
          label: const Text('SIMPAN'),
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
