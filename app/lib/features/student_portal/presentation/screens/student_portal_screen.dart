import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/student_portal_providers.dart';
import '../../domain/entities/student_portal_data.dart';
import '../../domain/entities/student_voice_submission.dart';
import 'package:app/features/discipline_counseling/domain/entities/school_announcement.dart';

class StudentPortalScreen extends ConsumerStatefulWidget {
  const StudentPortalScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends ConsumerState<StudentPortalScreen> {
  final _tokenController = TextEditingController();
  String? _activeToken;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      _activeToken = widget.initialToken;
      _tokenController.text = widget.initialToken!;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _submitToken() {
    final t = _tokenController.text.trim();
    if (t.isNotEmpty) {
      setState(() => _activeToken = t);
    }
  }

  void _openCameraScanner() {
    showDialog(
      context: context,
      builder: (ctx) => _CameraQrScannerDialog(
        onScanned: (token) {
          Navigator.pop(ctx);
          setState(() {
            _tokenController.text = token;
            _activeToken = token;
          });
        },
      ),
    );
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
              child: Text('PORTAL MURID — SUARA MURID', overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ],
        ),
        actions: [
          if (_activeToken != null)
            TextButton.icon(
              onPressed: () => setState(() => _activeToken = null),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Keluar'),
            ),
        ],
      ),
      body: _activeToken == null
          ? _StudentAuthView(
              tokenController: _tokenController,
              onSubmit: _submitToken,
              onOpenScanner: _openCameraScanner,
            )
          : _StudentDashboardView(
              qrToken: _activeToken!,
              onSignOut: () => setState(() => _activeToken = null),
            ),
    );
  }
}

class _StudentAuthView extends StatelessWidget {
  const _StudentAuthView({
    required this.tokenController,
    required this.onSubmit,
    required this.onOpenScanner,
  });

  final TextEditingController tokenController;
  final VoidCallback onSubmit;
  final VoidCallback onOpenScanner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.qr_code_scanner, size: 48, color: Colors.blue.shade800),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PORTAL MURID',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'D2C Summit • SMK Sungai Damit',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onOpenScanner,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('IMBAS KAD QR NAME TAG'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ATAU', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Masukkan Kod QR Name Tag',
                      hintText: 'cth: 8A2B9C0D',
                      prefixIcon: Icon(Icons.vpn_key),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => onSubmit(),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: onSubmit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Daftar Masuk Portal'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraQrScannerDialog extends StatefulWidget {
  const _CameraQrScannerDialog({required this.onScanned});

  final ValueChanged<String> onScanned;

  @override
  State<_CameraQrScannerDialog> createState() => _CameraQrScannerDialogState();
}

class _CameraQrScannerDialogState extends State<_CameraQrScannerDialog> {
  final _controller = MobileScannerController();
  bool _detected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Imbas QR Name Tag Murid'),
      content: SizedBox(
        width: 320,
        height: 320,
        child: MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_detected) return;
            final val = capture.barcodes.firstOrNull?.rawValue;
            if (val != null && val.isNotEmpty) {
              setState(() => _detected = true);
              widget.onScanned(val);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

class _StudentDashboardView extends ConsumerWidget {
  const _StudentDashboardView({
    required this.qrToken,
    required this.onSignOut,
  });

  final String qrToken;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(studentPortalDataProvider(qrToken));

    return dataAsync.when(
      data: (data) {
        if (data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Kod QR Tidak Sah atau Tidak Ditemui',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Sila pastikan anda mengimbas Kad Name Tag QR murid yang betul.'),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: onSignOut, child: const Text('Cuba Lagi')),
                ],
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHeader,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        data.fullName.isNotEmpty ? data.fullName[0].toUpperCase() : 'M',
                        style: TextStyle(fontSize: 20, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text('Kelas: ${data.className}'),
                        ],
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.military_tech, color: Colors.amber, size: 18),
                      label: Text('${data.totalMeritPoints} Merit', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.campaign), text: 'Pengumuman'),
                  Tab(icon: Icon(Icons.trending_up), text: 'Kemajuan Saya'),
                  Tab(icon: Icon(Icons.record_voice_over), text: 'Suara Murid'),
                  Tab(icon: Icon(Icons.auto_awesome), text: 'Inspirasi'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _AnnouncementsTab(announcements: data.announcements),
                    _MyProgressTab(data: data),
                    _StudentVoiceTab(data: data, qrToken: qrToken),
                    const _InspirationTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Ralat memuatkan portal: $err')),
    );
  }
}

extension _SurfaceColor on ColorScheme {
  Color get surfaceContainerHeader => brightness == Brightness.dark ? Colors.grey.shade900 : Colors.blue.shade50;
}

class _MyProgressTab extends StatelessWidget {
  const _MyProgressTab({required this.data});

  final StudentPortalData data;

  @override
  Widget build(BuildContext context) {
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
                      const Icon(Icons.fact_check, size: 32, color: Colors.green),
                      const SizedBox(height: 8),
                      Text('${data.attendanceRate.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.headlineMedium),
                      const Text('Kadar Kehadiran'),
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
                      const Icon(Icons.emoji_events, size: 32, color: Colors.amber),
                      const SizedBox(height: 8),
                      Text('${data.totalMeritPoints}', style: Theme.of(context).textTheme.headlineMedium),
                      const Text('Mata Merit'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rekod Kehadiran Terkini', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (data.recentAttendance.isEmpty)
                  const Text('Tiada rekod kehadiran terkini.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.recentAttendance.map((item) {
                      final status = item['status'] as String? ?? 'hadir';
                      final color = switch (status) {
                        'hadir' => Colors.green,
                        'lewat' => Colors.orange,
                        'tidak_hadir' => Colors.red,
                        _ => Colors.blue,
                      };
                      return Chip(
                        backgroundColor: color.withValues(alpha: 0.15),
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                        label: Text(
                          '${item['date']} (${status.toUpperCase()})',
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentVoiceTab extends ConsumerWidget {
  const _StudentVoiceTab({
    required this.data,
    required this.qrToken,
  });

  final StudentPortalData data;
  final String qrToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMM yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _openSubmitVoiceDialog(context, ref),
            icon: const Icon(Icons.add_comment),
            label: const Text('+ Hantar Suara Murid / Cadangan / Aduan'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: data.submissions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada hantaran Suara Murid. Tekan butang di atas untuk menyuarakan cadangan, maklum balas, atau aduan anda secara selamat.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.submissions.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = data.submissions[index];
                    final statusColor = switch (item.status) {
                      'selesai' => Colors.green,
                      'dalam_tindakan' => Colors.orange,
                      _ => Colors.blue,
                    };

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                        child: Icon(Icons.comment, color: statusColor),
                      ),
                      title: Text(item.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Kategori: ${StudentVoiceSubmission.categoryLabel(item.category)}'),
                          Text('Mesej: ${item.message}'),
                          Text('Tarikh Hantar: ${dateFormat.format(item.createdAt)}'),
                          if (item.responseNotes != null && item.responseNotes!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                'Maklum Balas Guru: ${item.responseNotes}',
                                style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(item.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openSubmitVoiceDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _SubmitVoiceDialog(
        studentId: data.studentId,
        qrToken: qrToken,
      ),
    );
  }
}

class _SubmitVoiceDialog extends ConsumerStatefulWidget {
  const _SubmitVoiceDialog({
    required this.studentId,
    required this.qrToken,
  });

  final String studentId;
  final String qrToken;

  @override
  ConsumerState<_SubmitVoiceDialog> createState() => _SubmitVoiceDialogState();
}

class _SubmitVoiceDialogState extends ConsumerState<_SubmitVoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'cadangan_sekolah';
  bool _isAnonymous = false;
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hantar Suara Murid (Cadangan / Aduan)'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Kategori Hantaran'),
                  items: const [
                    DropdownMenuItem(value: 'cadangan_sekolah', child: Text('Cadangan Penambahbaikan Sekolah')),
                    DropdownMenuItem(value: 'maklum_balas_pembelajaran', child: Text('Maklum Balas Pembelajaran & Kelas')),
                    DropdownMenuItem(value: 'aduan_buli_keselamatan', child: Text('Aduan Buli & Keselamatan Murid')),
                    DropdownMenuItem(value: 'permohonan_kaunseling', child: Text('Permohonan Sesi Kaunseling UBK')),
                  ],
                  onChanged: (val) => setState(() => _category = val!),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hantar Secara Rahsia (Anonymously)'),
                  subtitle: const Text('Identiti & nama anda tidak akan dipaparkan.'),
                  value: _isAnonymous,
                  onChanged: (val) => setState(() => _isAnonymous = val ?? false),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Tajuk / Perkara',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Sila isi tajuk.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Mesej / Butiran Cadangan atau Aduan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Sila isi mesej.' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting ? const CircularProgressIndicator() : const Text('Hantar Suara Murid'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(studentPortalRepositoryProvider).submitStudentVoice(
            studentId: widget.studentId,
            category: _category,
            isAnonymous: _isAnonymous,
            subject: _subjectController.text.trim(),
            message: _messageController.text.trim(),
          );

      ref.invalidate(studentPortalDataProvider(widget.qrToken));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suara Murid berjaya dihantar. Terima kasih!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghantar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _InspirationTab extends StatelessWidget {
  const _InspirationTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.format_quote, size: 40, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  '"Kejayaan Bermula Dengan Kehadiran & Sahsiah Teruji."',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 4),
                const Text('SMK Sungai Damit — Dare to Change (D2C)'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab({required this.announcements});

  final List<SchoolAnnouncement> announcements;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    if (announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Tiada Pengumuman Baru',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pengumuman rasmi daripada Guru Disiplin dan UBK akan dipaparkan di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ann = announcements[index];
        final isDiscipline = ann.category.toLowerCase() == 'disiplin';
        final catColor = isDiscipline ? Colors.amber.shade900 : Colors.purple.shade700;
        final catLabel = isDiscipline ? 'Pengumuman Disiplin' : 'Pengumuman Kaunseling UBK';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: catColor.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: catColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        catLabel,
                        style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateFormat.format(ann.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ann.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  ann.content,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                if (ann.targetStudentName != null && ann.targetStudentName!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.blue.shade800),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Murid Terlibat: ${ann.targetStudentName}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.account_circle, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Daripada: ${ann.authorName ?? "Pengurusan Sekolah"}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
