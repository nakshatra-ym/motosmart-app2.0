import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';

/// Navigation shell for the `CUSTOMER` route branches (home, service,
/// chatbot, profile). Layout — bar on a phone, rail on a tablet — is [AppShell]'s
/// job, shared with the dealer shell.
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navigationShell: navigationShell,
      tabs: const [
        ShellTab(
          icon: Icons.two_wheeler_outlined,
          selectedIcon: Icons.two_wheeler,
          label: 'My bike',
        ),
        ShellTab(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Service',
        ),
        ShellTab(
          icon: Icons.forum_outlined,
          selectedIcon: Icons.forum,
          label: 'Assistant',
        ),
        ShellTab(
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge,
          label: 'Profile',
        ),
      ],
    );
  }
}
