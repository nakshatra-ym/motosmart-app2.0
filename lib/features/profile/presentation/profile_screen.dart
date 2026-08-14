import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/app_visuals.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final employee = session?.employee;
    final theme = Theme.of(context);
    // Comes with `GET /me`. It used to be looked up in the offline mock store,
    // which holds no real branches, so signed-in staff saw a dash where their
    // own dealer should be.
    final dealer = session?.dealer;

    return AppPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Profile'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.yamahaBlue,
                        Color.lerp(AppColors.yamahaBlue, AppColors.brandInk, 0.35)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yamahaBlue.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (employee?.name ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                employee?.name ?? 'Unknown',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'DEALER STAFF',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.yamahaBlue,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const AppIconWell(
                        icon: Icons.mail_outline_rounded,
                        size: 40,
                        iconSize: 18,
                      ),
                      title: const Text('Email'),
                      subtitle: Text(employee?.email ?? '—'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const AppIconWell(
                        icon: Icons.phone_outlined,
                        size: 40,
                        iconSize: 18,
                        color: AppColors.accent,
                      ),
                      title: const Text('Phone'),
                      subtitle: Text(employee?.phone ?? '—'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const AppIconWell(
                        icon: Icons.storefront_outlined,
                        size: 40,
                        iconSize: 18,
                        color: AppColors.warm,
                      ),
                      title: const Text('Dealer'),
                      subtitle: Text(
                        dealer == null
                            ? '—'
                            : '${dealer.name} · ${dealer.code}\n${dealer.address}',
                      ),
                      isThreeLine: dealer != null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: ListTile(
                  leading: const AppIconWell(
                    icon: Icons.emoji_events_outlined,
                    size: 40,
                    iconSize: 18,
                    color: AppColors.yamahaRed,
                  ),
                  title: const Text('Incentives'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
                  onTap: () => context.push('/dealer/profile/incentives'),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.yamahaRed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
