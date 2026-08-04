import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/attendance/presentation/screens/attendance_status_screen.dart';
import '../../features/attendance/presentation/screens/manual_attendance_screen.dart';
import '../../features/attendance/presentation/screens/qr_scan_screen.dart';
import '../../features/attendance/presentation/screens/register_qr_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/class_management/presentation/screens/class_list_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/merit/presentation/screens/merit_class_summary_screen.dart';
import '../../features/merit/presentation/screens/merit_daily_screen.dart';
import '../../features/merit/presentation/screens/rewards_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/student/presentation/screens/student_list_screen.dart';
import '../layout/app_shell.dart';
import '../providers/supabase_provider.dart';
import 'hash_change_listenable.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = GoRouterRefreshStream(ref.watch(supabaseClientProvider).auth.onAuthStateChange);
  ref.onDispose(authRefresh.dispose);

  late final GoRouter router;
  router = GoRouter(
    initialLocation: '/',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final isSignedIn = ref.read(supabaseClientProvider).auth.currentSession != null;
      final isSigningIn = state.matchedLocation == '/sign-in';

      if (!isSignedIn) return isSigningIn ? null : '/sign-in';
      if (isSignedIn && isSigningIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/classes', builder: (context, state) => const ClassListScreen()),
          GoRoute(path: '/students', builder: (context, state) => const StudentListScreen()),
          GoRoute(path: '/attendance', builder: (context, state) => const AttendanceStatusScreen()),
          GoRoute(path: '/attendance/scan', builder: (context, state) => const QrScanScreen()),
          GoRoute(path: '/attendance/manual', builder: (context, state) => const ManualAttendanceScreen()),
          GoRoute(
            path: '/attendance/register-qr',
            builder: (context, state) => RegisterQrScreen(initialToken: state.extra as String?),
          ),
          GoRoute(path: '/merit', builder: (context, state) => const MeritDailyScreen()),
          GoRoute(path: '/merit/class-summary', builder: (context, state) => const MeritClassSummaryScreen()),
          GoRoute(path: '/merit/rewards', builder: (context, state) => const RewardsScreen()),
          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
  syncRouterWithExternalHashChanges(router);
  return router;
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
