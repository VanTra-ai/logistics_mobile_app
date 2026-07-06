import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// Màn hình vỏ bọc chính với BottomNavigationBar.
/// Được dùng như ShellRoute — nó render các tab bên trong `child`.
class MainShellScreen extends ConsumerStatefulWidget {
  /// Widget con được GoRouter ShellRoute inject vào (tab hiện tại).
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  // Danh sách các tab theo thứ tự
  static const List<_ShellTab> _tabs = [
    _ShellTab(
      label: 'Tổng quan',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      route: AppRoutes.dashboard,
    ),
    _ShellTab(
      label: 'Thông báo',
      icon: Icons.notifications_none_outlined,
      activeIcon: Icons.notifications,
      route: AppRoutes.notifications,
    ),
    _ShellTab(
      label: 'Cá nhân',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: AppRoutes.profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere(
      (tab) => location.startsWith(tab.route),
    );

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (index) =>
            context.go(_tabs[index].route),
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ShellTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _ShellTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
