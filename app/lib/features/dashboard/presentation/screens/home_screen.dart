import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/dashboard_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutMode = ref.watch(layoutModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    final firstName = profileAsync.value?.fullName.split(' ').first ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset('assets/images/crest.png', width: 28, height: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'DARE TO CHANGE (D2C)',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        titleSpacing: 16,
        actions: [
          IconButton(
            icon: Icon(AppTheme.iconFor(themeMode)),
            tooltip: 'Theme: ${AppTheme.labelFor(themeMode)}',
            onPressed: () => ref.read(themeModeProvider.notifier).state = AppTheme.nextThemeMode(themeMode),
          ),
          IconButton(
            icon: Icon(AppShell.iconFor(layoutMode)),
            tooltip: 'Layout: ${layoutMode.name}',
            onPressed: () => ref.read(layoutModeProvider.notifier).state = AppShell.next(layoutMode),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(supabaseClientProvider).auth.signOut(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1000
              ? 4
              : width >= 700
                  ? 3
                  : 2;
          final childAspectRatio = width >= 1000
              ? 1.15
              : width >= 700
                  ? 1.05
                  : 0.82;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WelcomeHeader(name: firstName),
                const SizedBox(height: 20),
                _QuickOverview(statsAsync: statsAsync),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _DashboardCard(
                      icon: Icons.groups,
                      label: 'Classes',
                      description: 'Manage class list & assignments',
                      paletteIndex: 0,
                      onTap: () => context.push('/classes'),
                    ),
                    _DashboardCard(
                      icon: Icons.people,
                      label: 'Students',
                      description: 'Browse and manage student records',
                      paletteIndex: 1,
                      onTap: () => context.push('/students'),
                    ),
                    _DashboardCard(
                      icon: Icons.fact_check,
                      label: 'Attendance',
                      description: 'View daily attendance records',
                      paletteIndex: 2,
                      onTap: () => context.push('/attendance'),
                    ),
                    _DashboardCard(
                      icon: Icons.qr_code_scanner,
                      label: 'Scan QR',
                      description: 'Scan student cards to mark attendance',
                      paletteIndex: 3,
                      onTap: () => context.push('/attendance/scan'),
                    ),
                    _DashboardCard(
                      icon: Icons.badge,
                      label: 'Register QR Card',
                      description: 'Assign QR cards to students',
                      paletteIndex: 4,
                      onTap: () => context.push('/attendance/register-qr'),
                    ),
                    _DashboardCard(
                      icon: Icons.military_tech,
                      label: 'Merit',
                      description: 'Track daily merit points',
                      paletteIndex: 5,
                      onTap: () => context.push('/merit'),
                    ),
                    _DashboardCard(
                      icon: Icons.leaderboard,
                      label: 'Class Summary',
                      description: 'Compare merit across classes',
                      paletteIndex: 6,
                      onTap: () => context.push('/merit/class-summary'),
                    ),
                    _DashboardCard(
                      icon: Icons.emoji_events,
                      label: 'Rewards',
                      description: 'Log and view award leaderboards',
                      paletteIndex: 7,
                      onTap: () => context.push('/merit/rewards'),
                    ),
                    _DashboardCard(
                      icon: Icons.insights,
                      label: 'Reports',
                      description: 'KPI dashboard & trends',
                      paletteIndex: 8,
                      onTap: () => context.push('/reports'),
                    ),
                    _DashboardCard(
                      icon: Icons.settings,
                      label: 'Settings',
                      description: 'Schedules & staff accounts',
                      paletteIndex: 9,
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(gradient: AppTheme.heroGradient, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            bottom: -30,
            child: Opacity(opacity: 0.14, child: Icon(Icons.school, size: 150, color: Colors.white)),
          ),
          Positioned(
            right: 70,
            top: -16,
            child: Opacity(opacity: 0.16, child: Icon(Icons.access_time_filled, size: 56, color: Colors.white)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $name! 👋',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Here's what's happening at school today.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.paletteIndex,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final int paletteIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, accent) = AppTheme.categoryPalette[paletteIndex % AppTheme.categoryPalette.length];
    return Card(
      color: bg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -14,
                top: -14,
                child: Opacity(opacity: 0.12, child: Icon(icon, size: 84, color: accent)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: accent,
                      child: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickOverview extends StatelessWidget {
  const _QuickOverview({required this.statsAsync});

  final AsyncValue<DashboardStats> statsAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Wrap(
                spacing: 28,
                runSpacing: 16,
                children: [
                  _StatItem(icon: Icons.groups, color: Colors.blue, value: '${stats.totalClasses}', label: 'Total Classes'),
                  _StatItem(icon: Icons.people, color: Colors.teal, value: '${stats.totalStudents}', label: 'Total Students'),
                  _StatItem(
                    icon: Icons.fact_check,
                    color: Colors.green,
                    value: '${(stats.attendanceRateToday * 100).round()}%',
                    label: 'Attendance Today',
                  ),
                  _StatItem(
                    icon: Icons.military_tech,
                    color: Colors.amber.shade800,
                    value: '${stats.totalMeritPoints}',
                    label: 'Merits Awarded',
                  ),
                  _StatItem(
                    icon: Icons.emoji_events,
                    color: Colors.pink,
                    value: '${stats.totalRewardsGiven}',
                    label: 'Rewards Given',
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: LinearProgressIndicator(),
              ),
              error: (error, stack) => const Text('Could not load overview stats.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
