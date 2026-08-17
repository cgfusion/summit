import 'package:app/features/landing/presentation/screens/school_landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SchoolLandingScreen Test', () {
    testWidgets('renders D2C hero spotlight and school title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SchoolLandingScreen(),
          ),
        ),
      );

      expect(find.text('SMK SUNGAI DAMIT'), findsWidgets);
      expect(find.textContaining('DARE TO'), findsWidgets);
      expect(find.text('"Hadir Hari Ini, Menang Esok Hari"'), findsOneWidget);
      expect(find.text('Saya Hadir, Saya Kekal, Saya Berjaya!'), findsOneWidget);
    });
  });
}
