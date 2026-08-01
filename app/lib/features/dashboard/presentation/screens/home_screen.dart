import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../../core/providers/supabase_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutMode = ref.watch(layoutModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('DARE TO CHANGE (D2C)'),
        actions: [
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
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _DashboardTile(icon: Icons.groups, label: 'Classes', color: Colors.blue, onTap: () => context.push('/classes')),
          _DashboardTile(icon: Icons.people, label: 'Students', color: Colors.teal, onTap: () => context.push('/students')),
          _DashboardTile(
            icon: Icons.fact_check,
            label: 'Attendance',
            color: Colors.green,
            onTap: () => context.push('/attendance'),
          ),
          _DashboardTile(
            icon: Icons.qr_code_scanner,
            label: 'Scan QR',
            color: Colors.indigo,
            onTap: () => context.push('/attendance/scan'),
          ),
          _DashboardTile(
            icon: Icons.badge,
            label: 'Register QR Card',
            color: Colors.purple,
            onTap: () => context.push('/attendance/register-qr'),
          ),
          _DashboardTile(icon: Icons.military_tech, label: 'Merit', color: Colors.amber, onTap: () => context.push('/merit')),
          _DashboardTile(
            icon: Icons.emoji_events,
            label: 'Rewards',
            color: Colors.pink,
            onTap: () => context.push('/merit/rewards'),
          ),
          _DashboardTile(icon: Icons.insights, label: 'Reports', color: Colors.cyan, onTap: () => context.push('/reports')),
          _DashboardTile(
            icon: Icons.settings,
            label: 'Settings',
            color: Colors.blueGrey,
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
