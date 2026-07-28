import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../student/domain/entities/student.dart';
import '../../../student/presentation/providers/student_providers.dart';
import '../../domain/entities/register_qr_result.dart';
import '../providers/attendance_providers.dart';

/// Lets a teacher bind a physical QR card to a student: pick the student,
/// then scan the card (or, when arriving from an "unrecognised card" scan,
/// the token is already known and only the student needs picking).
class RegisterQrScreen extends ConsumerStatefulWidget {
  const RegisterQrScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<RegisterQrScreen> createState() => _RegisterQrScreenState();
}

class _RegisterQrScreenState extends ConsumerState<RegisterQrScreen> {
  final _searchController = TextEditingController();
  List<Student> _searchResults = [];
  bool _searching = false;

  Student? _selectedStudent;
  String? _token;
  bool _processing = false;
  String? _feedback;
  Color? _feedbackColor;

  @override
  void initState() {
    super.initState();
    _token = widget.initialToken;
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    });
  }

  Future<void> _onCardDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null) return;
    setState(() => _token = token);
    await _submit();
  }

  Future<void> _submit({bool reissue = false}) async {
    final student = _selectedStudent;
    final token = _token;
    if (student == null || token == null) return;

    setState(() {
      _processing = true;
      _feedback = null;
    });

    final repository = ref.read(attendanceRepositoryProvider);
    try {
      final result = reissue
          ? await repository.reissueToken(studentId: student.id, token: token, printedClassSnapshot: student.className)
          : await repository.registerToken(studentId: student.id, token: token, printedClassSnapshot: student.className);

      switch (result) {
        case RegisterQrSuccess():
          _showFeedback('Registered — ${student.fullName} can now scan this card.', Colors.green);
          setState(() {
            _selectedStudent = null;
            _token = null;
          });
        case RegisterQrTokenTaken(:final registeredToStudentName):
          _showFeedback('This card is already registered to $registeredToStudentName.', Colors.red);
          setState(() => _token = null);
        case RegisterQrStudentHasToken():
          if (!mounted) return;
          final confirmed = await _confirmReplace(student.fullName);
          if (confirmed == true) {
            await _submit(reissue: true);
            return;
          }
          setState(() => _token = null);
      }
    } catch (error) {
      _showFeedback('Failed: $error', Colors.red);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<bool?> _confirmReplace(String studentName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace existing card?'),
        content: Text('$studentName already has a registered card. Replace it with the one just scanned?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Replace')),
        ],
      ),
    );
  }

  void _showFeedback(String message, Color color) {
    if (!mounted) return;
    setState(() {
      _feedback = message;
      _feedbackColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register QR Card')),
      body: Column(
        children: [
          if (_feedback != null)
            Container(
              width: double.infinity,
              color: _feedbackColor,
              padding: const EdgeInsets.all(12),
              child: Text(_feedback!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            ),
          Expanded(child: _selectedStudent == null ? _buildStudentPicker() : _buildScanStep()),
        ],
      ),
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
              labelText: 'Search student by name',
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
                subtitle: Text(student.className ?? '-'),
                onTap: () => _selectStudent(student),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanStep() {
    final student = _selectedStudent!;
    return Column(
      children: [
        ListTile(
          title: Text(student.fullName),
          subtitle: Text(student.className ?? '-'),
          trailing: TextButton(
            onPressed: _processing ? null : () => setState(() => _selectedStudent = null),
            child: const Text('Change'),
          ),
        ),
        const Divider(height: 1),
        if (widget.initialToken != null && _token == widget.initialToken)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code, size: 64),
                    const SizedBox(height: 16),
                    const Text('Use the card scanned earlier for this student?'),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _processing ? null : () => _submit(),
                      child: _processing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Stack(
              children: [
                MobileScanner(onDetect: _onCardDetected),
                if (_processing) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
      ],
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
