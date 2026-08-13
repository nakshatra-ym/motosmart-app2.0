import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/design.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/document.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/dashboard_summary.dart';
import '../../notifications/data/notification_providers.dart';
import '../data/dashboard_providers.dart';

/// Today's docket: the sheet a salesperson is handed at the start of a shift.
///
/// Work comes first and counts come second, which is the opposite of the metric
/// grid this replaced — a salesperson opens this to find out who to call, not to
/// read four numbers. The counts stay, compressed into one ledger strip.
class DealerDashboardScreen extends ConsumerWidget {
  const DealerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final employee = session?.employee;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
        child: AsyncValueWidget<DashboardSummary>(
          value: summary,
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
          data: (data) => CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Ds.surface,
                surfaceTintColor: Colors.transparent,
                titleSpacing: Ds.s4,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("TODAY'S DOCKET", style: Ds.label()),
                    Text(
                      employee == null
                          ? 'Dealer desk'
                          : employee.name.split(' ').first,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () =>
                        context.push('/dealer/dashboard/notifications'),
                    icon: Badge(
                      backgroundColor: Ds.alert,
                      label: Text(
                        '$unreadCount',
                        style: Ds.figure(10, weight: 700, color: Colors.white),
                      ),
                      isLabelVisible: unreadCount > 0,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                  ),
                  const SizedBox(width: Ds.s2),
                ],
              ),
              SliverPadding(
                padding: Ds.pagePad(context),
                sliver: SliverToBoxAdapter(
                  child: DocPage(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LedgerStrip(data: data),
                        const SizedBox(height: Ds.s5),
                        DocSectionHeader(
                          title: 'Due now',
                          count: data.todaysFollowups.length,
                        ),
                        if (data.todaysFollowups.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: Ds.s6),
                            child: EmptyState(
                              icon: Icons.event_available_outlined,
                              title: 'Nothing due today',
                              subtitle:
                                  'Follow-ups you schedule will appear here on the day they fall due.',
                            ),
                          )
                        else
                          for (final item in data.todaysFollowups)
                            Padding(
                              padding: const EdgeInsets.only(bottom: Ds.s3),
                              child: _FollowupRow(item: item),
                            ),
                        const SizedBox(height: Ds.s8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dealer/leads/new'),
        icon: const Icon(Icons.add),
        label: const Text('New enquiry'),
      ),
    );
  }
}

/// The day's figures as one ruled ledger strip.
///
/// Four numbers in a row of columns rather than four cards: on a form, related
/// figures share one band and are separated by rules, and it survives a narrow
/// phone without any card ever going square.
class _LedgerStrip extends StatelessWidget {
  const _LedgerStrip({required this.data});

  final DashboardSummary data;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, int, Color)>[
      ('New', data.newLeadsCount, Ds.info),
      ('Follow-up', data.followUpLeadsCount, Ds.caution),
      ('Hot', data.hotLeadsCount, Ds.alert),
      ('Closed', data.closedThisMonthCount, Ds.positive),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Ds.surfaceRaised,
        borderRadius: BorderRadius.circular(Ds.rMd),
        border: Border.all(color: Ds.lineStrong),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1, color: Ds.line),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Ds.s3,
                    horizontal: Ds.s2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Figures at the top so the eye reads the row as a line of
                      // numbers, with their names beneath as on a printed form.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${entries[i].$2}',
                          style: Ds.figure(24, weight: 720, color: entries[i].$3),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entries[i].$1.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Ds.label().copyWith(fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One due follow-up, as a docket line: who, what to do, and how late it is.
class _FollowupRow extends StatelessWidget {
  const _FollowupRow({required this.item});

  final FollowupWithLead item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final overdue = item.followup.isOverdue;
    final accent = overdue ? Ds.alert : Ds.caution;

    return DocSheet(
      spine: accent,
      onTap: () => context.push('/dealer/leads/${item.followup.leadId}'),
      padding: const EdgeInsets.all(Ds.s3 + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.leadCustomerName,
                  style: text.titleMedium?.copyWith(color: Ds.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Ds.s2),
              DocStamp(
                label: overdue ? 'Overdue' : 'Today',
                color: accent,
                filled: overdue,
              ),
            ],
          ),
          const SizedBox(height: Ds.s2),
          Text(
            item.followup.nextAction,
            style: text.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Ds.s2),
          Row(
            children: [
              const Icon(Icons.call_outlined, size: 13, color: Ds.inkMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  item.leadMobile,
                  style: Ds.figure(12.5, weight: 560, color: Ds.inkSoft),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
