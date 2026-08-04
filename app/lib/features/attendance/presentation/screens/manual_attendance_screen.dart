import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../class_management/presentation/providers/class_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../student/domain/entities/student.dart';
import '../../../student/presentation/providers/student_providers.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_status.dart';
import '../providers/attendance_providers.dart';

/// Lets a teacher key attendance in by hand, for students who didn't scan
/// their QR card, or to backfill a whole class/date from paper records.
class ManualAttendanceScreen extends StatelessWidget {
  const ManualAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: const HomeBackButton(),
          title: const Text('Manual Attendance'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Single Entry'),
              Tab(text: 'Bulk Migrate'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_SingleEntryTab(), _BulkMigrateTab()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single entry: search one student by name/IC, set status + date + time.
// ---------------------------------------------------------------------------

class _SingleEntryTab extends ConsumerStatefulWidget {
  const _SingleEntryTab();

  @override
  ConsumerState<_SingleEntryTab> createState() => _SingleEntryTabState();
}

class _SingleEntryTabState extends ConsumerState<_SingleEntryTab> {
  final _searchController = TextEditingController();
  final _noteController = TextEditingController();
  List<Student> _searchResults = [];
  bool _searching = false;

  Student? _selectedStudent;
  DateTime _date = DateTime.now();
  TimeOfDay? _time;
  AttendanceStatus _status = AttendanceStatus.hadir;
  bool _submitting = false;
  String? _feedback;
  Color? _feedbackColor;

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    final results = await ref.read(studentRepositoryProvider).getStudents(searchQuery: query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  void _selectStudent(Student student) {
    setState(() {
      _selectedStudent = student;
      _searchResults = [];
      _searchController.clear();
      _feedback = null;
      _status = AttendanceStatus.hadir;
      _time = null;
      _noteController.clear();
    });
  }

  Future<void> _submit() async {
    final student = _selectedStudent;
    if (student == null) return;

    setState(() {
      _submitting = true;
      _feedback = null;
    });

    try {
      final time = _time;
      await ref.read(attendanceRepositoryProvider).setManualAttendance(
            studentId: student.id,
            schoolDate: _date,
            status: _status,
            time: time == null ? null : DateTime(_date.year, _date.month, _date.day, time.hour, time.minute),
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(attendanceForDateProvider);
      invalidateDashboardAnalytics(ref);
      setState(() {
        _feedback = 'Saved: ${student.fullName} marked ${_status.label} on ${DateFormat('d MMM yyyy').format(_date)}.';
        _feedbackColor = Colors.green;
        _selectedStudent = null;
      });
    } catch (error) {
      setState(() {
        _feedback = 'Failed to save: $error';
        _feedbackColor = Colors.red;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_feedback != null)
          Container(
            width: double.infinity,
            color: _feedbackColor,
            padding: const EdgeInsets.all(12),
            child: Text(_feedback!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ),
        Expanded(child: _selectedStudent == null ? _buildStudentPicker() : _buildEntryForm()),
      ],
    );
  }

  Widget _buildStudentPicker() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search student by name or IC',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _search,
          ),
        ),
        if (_searching) const LinearProgressIndicator(),
        Expanded(
          child: ListView.separated(
            itemCount: _searchResults.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = _searchResults[index];
              return ListTile(
                title: Text(student.fullName),
                subtitle: Text([student.className ?? '-', if (student.icNumber != null) student.icNumber!].join(' • ')),
                onTap: () => _selectStudent(student),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEntryForm() {
    final student = _selectedStudent!;
    final needsTime = _status == AttendanceStatus.hadir || _status == AttendanceStatus.lewat;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(student.fullName),
          subtitle: Text(student.className ?? '-'),
          trailing: TextButton(
            onPressed: _submitting ? null : () => setState(() => _selectedStudent = null),
            child: const Text('Change'),
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text('Date: ${DateFormat('d MMM yyyy').format(_date)}'),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2025),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<AttendanceStatus>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
          items: [for (final s in AttendanceStatus.values) DropdownMenuItem(value: s, child: Text(s.label))],
          onChanged: (value) {
            if (value != null) setState(() => _status = value);
          },
        ),
        if (needsTime) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.access_time, size: 18),
            label: Text(_time == null ? 'Time (defaults to class cutoff)' : 'Time: ${_time!.format(context)}'),
            onPressed: () async {
              final picked = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
              if (picked != null) setState(() => _time = picked);
            },
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save Attendance'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bulk migrate: pick a class + date, only touch the absentees, everyone
// else in that class is saved as Hadir automatically.
// ---------------------------------------------------------------------------

class _BulkMigrateTab extends ConsumerStatefulWidget {
  const _BulkMigrateTab();

  @override
  ConsumerState<_BulkMigrateTab> createState() => _BulkMigrateTabState();
}

class _BulkMigrateTabState extends ConsumerState<_BulkMigrateTab> {
  String? _classId;
  DateTime _date = DateTime.now();
  bool _loadingRoster = false;
  List<Student> _roster = [];
  final Map<String, AttendanceStatus> _statusByStudent = {};
  bool _submitting = false;
  String? _feedback;
  Color? _feedbackColor;

  Future<void> _loadRoster() async {
    final classId = _classId;
    if (classId == null) return;
    setState(() {
      _loadingRoster = true;
      _roster = [];
      _statusByStudent.clear();
      _feedback = null;
    });
    final results = await Future.wait([
      ref.read(studentRepositoryProvider).getStudents(classId: classId),
      ref.read(attendanceRepositoryProvider).getAttendanceForDate(date: _date, classId: classId),
    ]);
    if (!mounted) return;
    final students = results[0] as List<Student>;
    final existing = results[1] as List<AttendanceDay>;
    final existingByStudent = {for (final day in existing) day.studentId: day.status};
    setState(() {
      _roster = students;
      for (final s in students) {
        _statusByStudent[s.id] = existingByStudent[s.id] ?? AttendanceStatus.hadir;
      }
      _loadingRoster = false;
    });
  }

  Future<void> _submit() async {
    if (_roster.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save attendance for whole class?'),
        content: Text(
          'This sets attendance for all ${_roster.length} students in this class on '
          '${DateFormat('d MMM yyyy').format(_date)}. Anyone not marked otherwise below will be saved as Hadir. '
          'This overwrites any existing record for that date.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _submitting = true;
      _feedback = null;
    });

    try {
      final repository = ref.read(attendanceRepositoryProvider);
      await Future.wait([
        for (final student in _roster)
          repository.setManualAttendance(
            studentId: student.id,
            schoolDate: _date,
            status: _statusByStudent[student.id] ?? AttendanceStatus.hadir,
          ),
      ]);
      if (!mounted) return;
      ref.invalidate(attendanceForDateProvider);
      invalidateDashboardAnalytics(ref);
      final exceptions = _statusByStudent.values.where((s) => s != AttendanceStatus.hadir).length;
      setState(() {
        _feedback = 'Saved ${_roster.length} students (${_roster.length - exceptions} Hadir, $exceptions marked otherwise).';
        _feedbackColor = Colors.green;
      });
    } catch (error) {
      setState(() {
        _feedback = 'Failed to save: $error';
        _feedbackColor = Colors.red;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return Column(
      children: [
        if (_feedback != null)
          Container(
            width: double.infinity,
            color: _feedbackColor,
            padding: const EdgeInsets.all(12),
            child: Text(_feedback!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: classesAsync.when(
                  data: (classes) => DropdownButtonFormField<String>(
                    initialValue: _classId,
                    decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                    items: [for (final c in classes) DropdownMenuItem(value: c.id, child: Text(c.name))],
                    onChanged: (value) {
                      setState(() => _classId = value);
                      _loadRoster();
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('Could not load classes'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(DateFormat('d MMM').format(_date)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                    _loadRoster();
                  }
                },
              ),
            ],
          ),
        ),
        if (_loadingRoster) const LinearProgressIndicator(),
        if (!_loadingRoster && _classId != null && _roster.isEmpty)
          const Expanded(child: Center(child: Text('No students in this class.'))),
        if (_roster.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tap a student to mark them absent/late/on-leave. Everyone else is saved as Hadir.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _roster.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = _roster[index];
                final status = _statusByStudent[student.id] ?? AttendanceStatus.hadir;
                return ListTile(
                  title: Text(student.fullName),
                  trailing: DropdownButton<AttendanceStatus>(
                    value: status,
                    underline: const SizedBox.shrink(),
                    items: [for (final s in AttendanceStatus.values) DropdownMenuItem(value: s, child: Text(s.label))],
                    onChanged: (value) {
                      if (value != null) setState(() => _statusByStudent[student.id] = value);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Save Attendance for ${_roster.length} students'),
            ),
          ),
        ],
      ],
    );
  }
}
