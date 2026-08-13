import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/app_visuals.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/dashboard_summary.dart';
import '../../notifications/data/notification_providers.dart';
import '../data/dashboard_providers.dart';

class DealerDashboardScreen extends ConsumerWidget {
  const DealerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final employee = ref.watch(authControllerProvider).valueOrNull?.employee;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final theme = Theme.of(context);
    final name = employee?.name.split(' ').first ?? 'Dealer';

    return AppPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.yamahaBlue,
            backgroundColor: AppColors.surface,
            onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
            child: AsyncValueWidget<DashboardSummary>(
              value: summary,
              onRetry: () => ref.invalidate(dashboardSummaryProvider),
              data: (data) => CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: FadeSlideIn(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'COMMAND CENTER',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: AppColors.yamahaBlue,
                                          letterSpacing: 2.2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const FloatingOrb(color: AppColors.accent, size: 8),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Hey, $name',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your dealership pulse — live.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.push('/dealer/dashboard/notifications'),
                            icon: Badge(
                              label: Text('$unreadCount'),
                              isLabelVisible: unreadCount > 0,
                              child: const Icon(Icons.notifications_none_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Bento row 1
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 60),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: GlassPanel(
                                    glow: AppColors.yamahaBlue,
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const AppIconWell(
                                              icon: Icons.bolt_rounded,
                                              size: 40,
                                              iconSize: 20,
                                              filled: true,
                                            ),
                                            const Spacer(),
                                            Text(
                                              'LIVE',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: AppColors.accent,
                                                letterSpacing: 1.6,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        Text('Pipeline heat', style: theme.textTheme.titleMedium),
                                        const SizedBox(height: 6),
                                        AnimatedMetric(
                                          value: data.hotLeadsCount,
                                          style: theme.textTheme.displaySmall?.copyWith(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        Text(
                                          'hot AI leads ready to close',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: _MiniMetric(
                                          label: 'New',
                                          value: data.newLeadsCount,
                                          color: AppColors.statusNew,
                                          icon: Icons.person_add_alt_1_rounded,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: _MiniMetric(
                                          label: 'Follow-ups',
                                          value: data.followUpLeadsCount,
                                          color: AppColors.statusFollowUp,
                                          icon: Icons.phone_forwarded_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: Row(
                            children: [
                              Expanded(
                                child: _MiniMetric(
                                  label: 'Closed',
                                  value: data.closedThisMonthCount,
                                  color: AppColors.statusClosedWon,
                                  icon: Icons.task_alt_rounded,
                                  tall: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: GlassPanel(
                                  glow: AppColors.yamahaRed,
                                  onTap: () => context.push('/dealer/leads/new'),
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    children: [
                                      const AppIconWell(
                                        icon: Icons.add_rounded,
                                        size: 44,
                                        iconSize: 24,
                                        color: AppColors.yamahaRed,
                                        filled: true,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Capture enquiry',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              'One tap → new lead',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.north_east_rounded, color: AppColors.inkFaint),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: Text(
                            "Today's follow-ups",
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (data.todaysFollowups.isEmpty)
                          const EmptyState(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'Inbox zero',
                            subtitle: 'Nothing due today. New and overdue follow-ups land here.',
                          )
                        else
                          ...data.todaysFollowups.asMap().entries.map((entry) {
                            final item = entry.value;
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 200 + entry.key * 40),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassPanel(
                                  onTap: () => context.push('/dealer/leads/${item.followup.leadId}'),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      AppIconWell(
                                        icon: item.followup.isOverdue
                                            ? Icons.warning_amber_rounded
                                            : Icons.event_available_rounded,
                                        size: 44,
                                        iconSize: 20,
                                        color: item.followup.isOverdue
                                            ? AppColors.hot
                                            : AppColors.yamahaBlue,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.leadCustomerName,
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '${item.followup.nextAction} · ${item.leadMobile}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        item.followup.isOverdue ? 'OVERDUE' : 'TODAY',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: item.followup.isOverdue
                                              ? AppColors.hot
                                              : AppColors.statusFollowUp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.tall = true,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      glow: color,
      padding: EdgeInsets.all(tall ? 16 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconWell(icon: icon, size: 34, iconSize: 16, color: color),
          if (tall) const Spacer() else const SizedBox(height: 12),
          AnimatedMetric(
            value: value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
