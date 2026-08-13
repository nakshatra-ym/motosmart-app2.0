import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/theme.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../models/dealer.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final employee = session?.employee;
    final store = ref.watch(mockDataStoreProvider);
    final theme = Theme.of(context);
    Dealer? dealer;
    if (employee != null) {
      for (final d in store.dealers) {
        if (d.id == employee.dealerId) {
          dealer = d;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.yamahaBlue,
                child: Text(
                  (employee?.name ?? '?').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              employee?.name ?? 'Unknown',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Dealer Staff',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 28),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(employee?.email ?? '—'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Phone'),
                    subtitle: Text(employee?.phone ?? '—'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.store_outlined),
                    title: const Text('Dealer'),
                    subtitle: Text(dealer == null ? '—' : '${dealer.name} · ${dealer.city}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Incentives'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.inkFaint),
                onTap: () => context.push('/dealer/profile/incentives'),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.yamahaRed),
            ),
          ],
        ),
      ),
    );
  }
}
