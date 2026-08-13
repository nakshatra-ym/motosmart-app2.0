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

    return AppPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee == null ? 'Dashboard' : 'Hi, ${employee.name.split(' ').first}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Dealer desk',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          actions: [
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
        body: RefreshIndicator(
          color: AppColors.yamahaBlue,
          onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
          child: AsyncValueWidget<DashboardSummary>(
            value: summary,
            onRetry: () => ref.invalidate(dashboardSummaryProvider),
            data: (data) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'New leads',
                        value: data.newLeadsCount,
                        color: AppColors.statusNew,
                        icon: Icons.person_add_alt_1_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Follow-ups',
                        value: data.followUpLeadsCount,
                        color: AppColors.statusFollowUp,
                        icon: Icons.phone_forwarded_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Hot leads (AI)',
                        value: data.hotLeadsCount,
                        color: AppColors.hot,
                        icon: Icons.local_fire_department_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Closed this month',
                        value: data.closedThisMonthCount,
                        color: AppColors.statusClosedWon,
                        icon: Icons.task_alt_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/dealer/leads/new'),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Capture new enquiry'),
                  ),
                ),
                const SizedBox(height: 28),
                Text("Today's follow-ups", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (data.todaysFollowups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Nothing due today',
                      subtitle: 'New and overdue follow-ups will show up here.',
                    ),
                  )
                else
                  ...data.todaysFollowups.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: AppIconWell(
                          icon: item.followup.isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.event_available_rounded,
                          size: 44,
                          iconSize: 20,
                          color: item.followup.isOverdue ? AppColors.hot : AppColors.yamahaBlue,
                        ),
                        title: Text(item.leadCustomerName, style: theme.textTheme.titleSmall),
                        subtitle: Text(
                          '${item.followup.nextAction} · ${item.leadMobile}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          item.followup.isOverdue ? 'Overdue' : 'Today',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: item.followup.isOverdue ? AppColors.hot : AppColors.statusFollowUp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () => context.push('/dealer/leads/${item.followup.leadId}'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconWell(icon: icon, size: 40, iconSize: 18, color: color),
          const SizedBox(height: 14),
          Text(
            '$value',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
