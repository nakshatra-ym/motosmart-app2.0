import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/design.dart';

/// One navigation destination, plus the badge count some of them carry.
class ShellTab {
  const ShellTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Unread count. Zero hides the badge.
  final int badge;
}

/// The shared chrome for both role shells.
///
/// Material asks for a navigation bar on a compact window and a navigation rail
/// on an expanded one, so a tablet gets a rail down the side and the content
/// keeps a readable measure instead of a phone's bottom bar stretched across
/// 1200dp. Both shells route through here so the two never drift apart.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.tabs,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellTab> tabs;

  void _select(int index) => navigationShell.goBranch(
        index,
        // Tapping the current tab returns to that branch's root, which is the
        // behaviour Android users expect from a navigation bar.
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final expanded = Ds.isExpanded(context);

    if (expanded) {
      return Scaffold(
        body: Row(
          children: [
            _Rail(
              tabs: tabs,
              selectedIndex: navigationShell.currentIndex,
              onSelected: _select,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Ds.line),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        // A hairline instead of an elevation shadow: the bar is a strip of the
        // same paper, ruled off from the content above it.
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Ds.line)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final tab in tabs)
              NavigationDestination(
                icon: _Badged(count: tab.badge, child: Icon(tab.icon)),
                selectedIcon:
                    _Badged(count: tab.badge, child: Icon(tab.selectedIcon)),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// The expanded-window rail, with the branch code plate at the top the way a
/// filing cabinet is labelled.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ShellTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -0.85,
      leading: const Padding(
        padding: EdgeInsets.only(top: Ds.s5, bottom: Ds.s6),
        child: _RailMark(),
      ),
      destinations: [
        for (final tab in tabs)
          NavigationRailDestination(
            icon: _Badged(count: tab.badge, child: Icon(tab.icon)),
            selectedIcon:
                _Badged(count: tab.badge, child: Icon(tab.selectedIcon)),
            label: Text(tab.label),
            padding: const EdgeInsets.symmetric(vertical: Ds.s1),
          ),
      ],
    );
  }
}

/// The product's mark on the rail: a plate stub, since that is this world's
/// identity device.
class _RailMark extends StatelessWidget {
  const _RailMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Ds.s2, vertical: 5),
      decoration: BoxDecoration(
        color: Ds.ink,
        borderRadius: BorderRadius.circular(Ds.rSm),
      ),
      child: Text('YMSLI', style: Ds.figure(11, color: const Color(0xFFF7F5EF))),
    );
  }
}

/// An unread count on a destination icon: a small stamped square, not a red dot.
class _Badged extends StatelessWidget {
  const _Badged({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Badge(
      backgroundColor: Ds.alert,
      textColor: Colors.white,
      // Squared off, so it reads as part of the document system.
      padding: const EdgeInsets.symmetric(horizontal: 4),
      label: Text(
        count > 99 ? '99+' : '$count',
        style: Ds.figure(10, weight: 700, color: Colors.white),
      ),
      child: child,
    );
  }
}
