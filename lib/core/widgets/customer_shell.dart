import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';

/// Bottom-nav shell for the `CUSTOMER` route branches (home, service,
/// chatbot, profile).
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandInk.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.two_wheeler_outlined),
              selectedIcon: Icon(Icons.two_wheeler_rounded),
              label: 'My bike',
            ),
            NavigationDestination(
              icon: Icon(Icons.handyman_outlined),
              selectedIcon: Icon(Icons.handyman_rounded),
              label: 'Service',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded),
              label: 'Assistant',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
