import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('shows configuration guidance when Supabase env vars are missing', (WidgetTester tester) async {
    await tester.pumpWidget(const MissingConfigApp());

    expect(find.textContaining('Missing Supabase configuration'), findsOneWidget);
  });
}
