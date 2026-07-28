import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/entities/attendance_status.dart';
import '../providers/attendance_providers.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _controller = MobileScannerController();
  bool _processing = false;
  String? _lastToken;
  String? _feedback;
  Color? _feedbackColor;
  String? _unrecognisedToken;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null || token == _lastToken) return;

    setState(() {
      _processing = true;
      _lastToken = token;
      _unrecognisedToken = null;
    });

    final repository = ref.read(attendanceRepositoryProvider);
    try {
      final student = await repository.resolveQrToken(token);
      if (student == null) {
        setState(() => _unrecognisedToken = token);
        _showFeedback('Unrecognised QR code.', Colors.red);
        return;
      }

      await repository.recordScan(studentId: student.id, deviceLabel: 'mobile-app');
      final today = await repository.getAttendanceForStudentOnDate(studentId: student.id, date: DateTime.now());
      final statusLabel = today?.status.label ?? 'recorded';
      final color = switch (today?.status) {
        AttendanceStatus.hadir => Colors.green,
        AttendanceStatus.lewat => Colors.orange,
        _ => Colors.blueGrey,
      };
      _showFeedback('${student.fullName} — $statusLabel', color);
    } catch (error) {
      _showFeedback('Scan failed: $error', Colors.red);
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _processing = false;
          _lastToken = null;
        });
      }
    }
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
      appBar: AppBar(title: const Text('Scan Attendance QR')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          if (_feedback != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                color: (_feedbackColor ?? Colors.black).withValues(alpha: 0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _feedback!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_unrecognisedToken != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                        icon: const Icon(Icons.badge),
                        label: const Text('Register this card'),
                        onPressed: () => context.push('/attendance/register-qr', extra: _unrecognisedToken),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (_processing)
            const Positioned(top: 16, right: 16, child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
