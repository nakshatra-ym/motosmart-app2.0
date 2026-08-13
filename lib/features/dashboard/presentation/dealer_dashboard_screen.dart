import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/theme.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(employee == null ? 'Dashboard' : 'Hi, ${employee.name.split(' ').first}'),
        actions: [
          IconButton(
            onPressed: () => context.push('/dealer/dashboard/notifications'),
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
        child: AsyncValueWidget<DashboardSummary>(
          value: summary,
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'New leads',
                      value: data.newLeadsCount,
                      color: AppColors.statusNew,
                      icon: Icons.person_add_alt_1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Follow-ups',
                      value: data.followUpLeadsCount,
                      color: AppColors.statusFollowUp,
                      icon: Icons.phone_forwarded,
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
                      icon: Icons.whatshot,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Closed this month',
                      value: data.closedThisMonthCount,
                      color: AppColors.statusClosedWon,
                      icon: Icons.task_alt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/dealer/leads/new'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Capture new enquiry'),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "Today's follow-ups",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (data.todaysFollowups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'Nothing due today',
                    subtitle: 'New and overdue follow-ups will show up here.',
                  ),
                )
              else
                ...data.todaysFollowups.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: item.followup.isOverdue
                            ? AppColors.hot.withValues(alpha: 0.12)
                            : AppColors.yamahaBlue.withValues(alpha: 0.1),
                        child: Icon(
                          item.followup.isOverdue ? Icons.warning_amber : Icons.event_available,
                          color: item.followup.isOverdue ? AppColors.hot : AppColors.yamahaBlue,
                          size: 20,
                        ),
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
                          fontWeight: FontWeight.w600,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 14),
            Text(
              '$value',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
