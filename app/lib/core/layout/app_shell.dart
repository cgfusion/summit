import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/presentation/providers/settings_providers.dart';
import '../providers/supabase_provider.dart';
import '../theme/app_theme.dart';

enum LayoutMode { auto, sidebar, compact }

final layoutModeProvider = StateProvider<LayoutMode>((ref) => LayoutMode.auto);

/// Below this width, `auto` mode shows the plain (no-shell) mobile layout;
/// at or above it, `auto` mode shows the sidebar. Chosen to comfortably sit
/// under iPad portrait (~768-820px) and above phone portrait (~360-430px).
const _sidebarBreakpoint = 720.0;

class _NavItem {
  const _NavItem(this.icon, this.label, this.path);

  final IconData icon;
  final String label;
  final String path;
}

const _navItems = [
  _NavItem(Icons.dashboard_outlined, 'Dashboard', '/'),
  _NavItem(Icons.home_outlined, 'Home', '/home'),
  _NavItem(Icons.groups_outlined, 'Classes', '/classes'),
  _NavItem(Icons.people_outline, 'Students', '/students'),
  _NavItem(Icons.fact_check_outlined, 'Attendance', '/attendance'),
  _NavItem(Icons.qr_code_scanner, 'Scan QR', '/attendance/scan'),
  _NavItem(Icons.edit_calendar_outlined, 'Manual Attendance', '/attendance/manual'),
  _NavItem(Icons.badge_outlined, 'Register QR Card', '/attendance/register-qr'),
  _NavItem(Icons.military_tech_outlined, 'Merit', '/merit'),
  _NavItem(Icons.leaderboard_outlined, 'Class Summary', '/merit/class-summary'),
  _NavItem(Icons.emoji_events_outlined, 'Rewards', '/merit/rewards'),
  _NavItem(Icons.gavel_outlined, 'Disiplin & Kaunseling', '/discipline-counseling'),
  _NavItem(Icons.insights_outlined, 'Reports', '/reports'),
  _NavItem(Icons.settings_outlined, 'Settings', '/settings'),
];

/// AppBar `leading` for every non-Dashboard/non-Home screen. In mobile mode
/// (no persistent sidebar) these screens are the only way back to Home, so
/// this always navigates there instead of relying on the default back
/// button, which silently disappears whenever there's nothing left to pop
/// (deep link, page reload, etc).
class HomeBackButton extends StatelessWidget {
  const HomeBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Home',
      onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
    );
  }
}

/// Responsive shell: below [_sidebarBreakpoint] (or when forced via
/// [layoutModeProvider]), renders [child] untouched -- exactly today's
/// mobile behaviour, each screen keeps its own AppBar/back-navigation. At or
/// above the breakpoint, wraps [child] in a persistent sidebar layout.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  static IconData iconFor(LayoutMode mode) => switch (mode) {
        LayoutMode.auto => Icons.auto_awesome_outlined,
        LayoutMode.sidebar => Icons.view_sidebar_outlined,
        LayoutMode.compact => Icons.grid_view_outlined,
      };

  static LayoutMode next(LayoutMode mode) => switch (mode) {
        LayoutMode.auto => LayoutMode.sidebar,
        LayoutMode.sidebar => LayoutMode.compact,
        LayoutMode.compact => LayoutMode.auto,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(layoutModeProvider);
    final width = MediaQuery.sizeOf(context).width;
    final useSidebar = switch (mode) {
      LayoutMode.sidebar => true,
      LayoutMode.compact => false,
      LayoutMode.auto => width >= _sidebarBreakpoint,
    };

    if (!useSidebar) return child;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(currentPath: currentPath),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(layoutModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 12, 24),
            decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset('assets/images/crest.png', width: 36, height: 36, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DARE TO CHANGE (D2C)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'School Management System',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(AppTheme.iconFor(themeMode), color: Colors.white, size: 20),
                  tooltip: 'Theme: ${AppTheme.labelFor(themeMode)}',
                  onPressed: () => ref.read(themeModeProvider.notifier).state = AppTheme.nextThemeMode(themeMode),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(AppShell.iconFor(mode), color: Colors.white, size: 20),
                  tooltip: 'Layout: ${mode.name}',
                  onPressed: () => ref.read(layoutModeProvider.notifier).state = AppShell.next(mode),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final item in _navItems) _SidebarTile(item: item, selected: item.path == currentPath),
              ],
            ),
          ),
          const Divider(height: 1),
          const _AccountFooter(),
        ],
      ),
    );
  }
}

class _AccountFooter extends ConsumerWidget {
  const _AccountFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final colorScheme = Theme.of(context).colorScheme;
    final name = profile?.fullName ?? 'Signed in';
    final role = profile?.role;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(initial, style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (role != null)
                  Text(
                    role[0].toUpperCase() + role.substring(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Sign out',
            onPressed: () => ref.read(supabaseClientProvider).auth.signOut(),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(item.icon, color: selected ? colorScheme.onPrimaryContainer : null),
          title: Text(
            item.label,
            style: TextStyle(
              color: selected ? colorScheme.onPrimaryContainer : null,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () => context.go(item.path),
        ),
      ),
    );
  }
}
