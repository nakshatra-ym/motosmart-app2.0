import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/data/notification_providers.dart';
import 'app_shell.dart';

/// Bottom-nav shell for the `DEALER_STAFF` route branches (dashboard, leads,
/// tickets, profile). [StatefulShellRoute.indexedStack] keeps each
/// branch's navigation stack alive when switching tabs.
///
/// Also refreshes notifications — the Firebase-free "push" PLAN_frontend.md
/// describes: on app resume, and on a light foreground poll while this
/// shell is on screen. The poll is a plain `Timer.periodic` cancelled in
/// [dispose], not a Riverpod stream provider — that would leave a `Timer`
/// whose cancellation is GC-timed rather than deterministic, which trips
/// the widget-test harness's pending-timer leak check.
class DealerShell extends ConsumerStatefulWidget {
  const DealerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<DealerShell> createState() => _DealerShellState();
}

class _DealerShellState extends ConsumerState<DealerShell> with WidgetsBindingObserver {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(notificationsListProvider);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationsListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The unread count rides on the Tickets tab, since a service reply is what
    // the dealer is being notified about.
    final unread = ref.watch(unreadNotificationsCountProvider);

    return AppShell(
      navigationShell: widget.navigationShell,
      tabs: [
        const ShellTab(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: 'Docket',
        ),
        const ShellTab(
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          label: 'Leads',
        ),
        ShellTab(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Tickets',
          badge: unread,
        ),
        const ShellTab(
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge,
          label: 'Profile',
        ),
      ],
    );
  }
}
