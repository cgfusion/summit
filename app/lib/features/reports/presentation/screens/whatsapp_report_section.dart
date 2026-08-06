import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../class_management/domain/entities/school_class.dart';
import '../../../class_management/presentation/providers/class_providers.dart';
import '../../../dashboard/domain/entities/attendance_period_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart' show attendancePeriodSummaryProvider;
import '../../../student/domain/entities/student.dart';
import '../../../student/presentation/providers/student_providers.dart';

const _malayMonths = [
  '',
  'Januari',
  'Februari',
  'Mac',
  'April',
  'Mei',
  'Jun',
  'Julai',
  'Ogos',
  'September',
  'Oktober',
  'November',
  'Disember',
];

// DateTime.weekday: 1=Monday .. 7=Sunday.
const _malayDays = ['', 'Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu', 'Ahad'];

String _malayDate(DateTime date) => '${date.day.toString().padLeft(2, '0')} ${_malayMonths[date.month]} ${date.year}';

String _malayDayName(DateTime date) => _malayDays[date.weekday];

/// "1 CITRA" -> "1 Citra", but short (<=3 letter) words are left alone --
/// several Form 4/5 class names are initialisms (UKM, UMS, UPM, UTM) that
/// would read wrong title-cased.
String _displayClassName(String name) {
  return name
      .split(' ')
      .map((word) => word.length <= 3 ? word : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

/// Builds the exact WhatsApp PIBG-group attendance report text for one or
/// more Tingkatan on [date], matching the school's existing manual format
/// verbatim (including the "Semua Murid Hadir Tahniah" congratulations line
/// when a class has zero absences, and the dashed separator between
/// Tingkatan blocks).
String buildAttendanceWhatsAppReport({
  required DateTime date,
  required List<int> tingkatanList,
  required List<AttendancePeriodSummary> periodSummary,
  required List<SchoolClass> classes,
}) {
  final formRowByTingkatan = <int, AttendancePeriodSummary>{
    for (final row in periodSummary.where((r) => r.scope == AttendanceSummaryScope.form))
      int.parse(row.scopeName.replaceFirst('Tingkatan ', '')): row,
  };
  final classRowById = {
    for (final row in periodSummary.where((r) => r.scope == AttendanceSummaryScope.class_)) row.scopeId: row,
  };

  final buffer = StringBuffer();
  for (var i = 0; i < tingkatanList.length; i++) {
    final tingkatan = tingkatanList[i];
    buffer.writeln('Kehadiran pelajar tingkatan $tingkatan');
    buffer.writeln('Tarikh ${_malayDate(date)}/ ${_malayDayName(date)}');
    buffer.writeln();

    final classesInForm = classes.where((c) => c.formLevel == tingkatan).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final schoolClass in classesInForm) {
      final row = classRowById[schoolClass.id];
      final present = row?.dayPresent ?? 0;
      final total = row?.dayTotal ?? 0;
      final absent = total - present;
      buffer.writeln('${_displayClassName(schoolClass.name)}   $present/$total orang');
      buffer.writeln(total > 0 && absent == 0 ? 'Semua Murid Hadir Tahniah' : '$absent orang tidak hadir');
      buffer.writeln();
    }

    final formRow = formRowByTingkatan[tingkatan];
    final formPresent = formRow?.dayPresent ?? 0;
    final formTotal = formRow?.dayTotal ?? 0;
    final formAbsent = formTotal - formPresent;
    final hadirPct = formTotal == 0 ? 0 : (formPresent / formTotal * 100).round();
    final tidakPct = 100 - hadirPct;
    buffer.writeln('Kehadiran  $formPresent/$formTotal orang');
    buffer.writeln('Peratus hadir $hadirPct%');
    buffer.writeln();
    buffer.writeln('Tidak hadir $formAbsent orang');
    buffer.write('Peratus tidak hadir $tidakPct%');

    if (i < tingkatanList.length - 1) {
      buffer.writeln();
      buffer.writeln('——————————————————');
    }
  }
  buffer.writeln();
  buffer.writeln();
  buffer.write('Terima kasih');
  return buffer.toString();
}

/// The Reports screen's "WhatsApp Reports" section: one ready-to-copy
/// attendance report per session (Petang = Tingkatan 1-2, Pagi = Tingkatan
/// 3-5, derived from classes.session rather than hardcoded, so it stays
/// correct if the school's session/Tingkatan mapping ever changes), plus a
/// free-text discipline announcement composer.
class WhatsAppReportSection extends ConsumerStatefulWidget {
  const WhatsAppReportSection({super.key});

  @override
  ConsumerState<WhatsAppReportSection> createState() => _WhatsAppReportSectionState();
}

class _WhatsAppReportSectionState extends ConsumerState<WhatsAppReportSection> {
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final referenceDate = DateTime(_date.year, _date.month, _date.day);
    final summaryAsync = ref.watch(attendancePeriodSummaryProvider(referenceDate));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat_outlined, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('WhatsApp PIBG Reports', style: Theme.of(context).textTheme.titleMedium),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_malayDate(referenceDate)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: referenceDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ],
            ),
            Text(
              'Generates the exact attendance message for the PIBG group -- copy and paste into WhatsApp yourself.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            classesAsync.when(
              data: (classes) => summaryAsync.when(
                data: (summary) {
                  final petangTingkatan = classes
                      .where((c) => c.session == 'petang')
                      .map((c) => c.formLevel)
                      .toSet()
                      .toList()
                    ..sort();
                  final pagiTingkatan = classes
                      .where((c) => c.session == 'pagi')
                      .map((c) => c.formLevel)
                      .toSet()
                      .toList()
                    ..sort();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 800;
                      final petangCard = _SessionReportCard(
                        title: 'Sesi Petang (Tingkatan ${petangTingkatan.join('-')})',
                        text: petangTingkatan.isEmpty
                            ? null
                            : buildAttendanceWhatsAppReport(
                                date: referenceDate,
                                tingkatanList: petangTingkatan,
                                periodSummary: summary,
                                classes: classes,
                              ),
                      );
                      final pagiCard = _SessionReportCard(
                        title: 'Sesi Pagi (Tingkatan ${pagiTingkatan.join('-')})',
                        text: pagiTingkatan.isEmpty
                            ? null
                            : buildAttendanceWhatsAppReport(
                                date: referenceDate,
                                tingkatanList: pagiTingkatan,
                                periodSummary: summary,
                                classes: classes,
                              ),
                      );
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: petangCard),
                            const SizedBox(width: 12),
                            Expanded(child: pagiCard),
                          ],
                        );
                      }
                      return Column(children: [petangCard, const SizedBox(height: 12), pagiCard]);
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => Text('Failed to load: $error'),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Text('Failed to load: $error'),
            ),
            const SizedBox(height: 12),
            const _AnnouncementCard(),
          ],
        ),
      ),
    );
  }
}

class _SessionReportCard extends StatelessWidget {
  const _SessionReportCard({required this.title, required this.text});

  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
              if (text != null)
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  tooltip: 'Copy',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report copied. Paste it into WhatsApp.')),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                text ?? 'No classes found for this session.',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends ConsumerStatefulWidget {
  const _AnnouncementCard();

  @override
  ConsumerState<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends ConsumerState<_AnnouncementCard> {
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _attachStudent() async {
    final student = await showDialog<Student>(
      context: context,
      builder: (dialogContext) => const _AttachStudentDialog(),
    );
    if (student != null) {
      _bodyController.text = 'Nama: ${student.fullName}\nKelas: ${student.className ?? '-'}\n\n${_bodyController.text}';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_outlined, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Expanded(child: Text('Special Announcement (Discipline)', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          Text(
            'Ad hoc -- only when needed, not part of the daily attendance report.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.person_search, size: 18),
            label: const Text('Attach Student (optional)'),
            onPressed: _attachStudent,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            maxLines: 6,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: 'Type the announcement here...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy'),
              onPressed: _bodyController.text.trim().isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: _bodyController.text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Announcement copied. Paste it into WhatsApp.')),
                        );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachStudentDialog extends ConsumerStatefulWidget {
  const _AttachStudentDialog();

  @override
  ConsumerState<_AttachStudentDialog> createState() => _AttachStudentDialogState();
}

class _AttachStudentDialogState extends ConsumerState<_AttachStudentDialog> {
  final _searchController = TextEditingController();
  List<Student> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final results = await ref.read(studentRepositoryProvider).getStudents(searchQuery: query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Attach a Student'),
      content: SizedBox(
        width: 360,
        height: 360,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Search by name or IC', prefixIcon: Icon(Icons.search)),
              onChanged: _search,
            ),
            if (_searching) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final student = _results[index];
                  return ListTile(
                    title: Text(student.fullName),
                    subtitle: Text(student.className ?? '-'),
                    onTap: () => Navigator.pop(context, student),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}
