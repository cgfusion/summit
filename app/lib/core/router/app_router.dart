import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/attendance/presentation/screens/attendance_status_screen.dart';
import '../../features/attendance/presentation/screens/qr_scan_screen.dart';
import '../../features/attendance/presentation/screens/register_qr_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/class_management/presentation/screens/class_list_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/student/presentation/screens/student_list_screen.dart';
import '../providers/supabase_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref.watch(supabaseClientProvider).auth.onAuthStateChange),
    redirect: (context, state) {
      final isSignedIn = ref.read(supabaseClientProvider).auth.currentSession != null;
      final isSigningIn = state.matchedLocation == '/sign-in';

      if (!isSignedIn) return isSigningIn ? null : '/sign-in';
      if (isSignedIn && isSigningIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/classes', builder: (context, state) => const ClassListScreen()),
      GoRoute(path: '/students', builder: (context, state) => const StudentListScreen()),
      GoRoute(path: '/attendance', builder: (context, state) => const AttendanceStatusScreen()),
      GoRoute(path: '/attendance/scan', builder: (context, state) => const QrScanScreen()),
      GoRoute(
        path: '/attendance/register-qr',
        builder: (context, state) => RegisterQrScreen(initialToken: state.extra as String?),
      ),
    ],
  );
});

/// Bridges a [Stream] (Supabase's auth-state stream) into a [Listenable] so
/// GoRouter re-evaluates `redirect` whenever auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
