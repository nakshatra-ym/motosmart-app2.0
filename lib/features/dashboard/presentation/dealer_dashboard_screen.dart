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
            padding: const EdgeInsets.all(16),
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
              ElevatedButton.icon(
                onPressed: () => context.push('/dealer/leads/new'),
                icon: const Icon(Icons.add),
                label: const Text('Capture new enquiry'),
              ),
              const SizedBox(height: 24),
              Text(
                "Today's follow-ups",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.followup.isOverdue
                            ? AppColors.hot.withValues(alpha: 0.15)
                            : AppColors.yamahaBlue.withValues(alpha: 0.1),
                        child: Icon(
                          item.followup.isOverdue ? Icons.warning_amber : Icons.event_available,
                          color: item.followup.isOverdue ? AppColors.hot : AppColors.yamahaBlue,
                          size: 20,
                        ),
                      ),
                      title: Text(item.leadCustomerName),
                      subtitle: Text('${item.followup.nextAction} · ${item.leadMobile}'),
                      trailing: item.followup.isOverdue
                          ? const Text('Overdue', style: TextStyle(color: AppColors.hot, fontSize: 12))
                          : const Text('Today', style: TextStyle(color: AppColors.statusFollowUp, fontSize: 12)),
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
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
