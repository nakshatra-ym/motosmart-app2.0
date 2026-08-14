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

  /// Beyond this the metrics stop stretching and the page centres, so a tablet
  /// gets a readable column instead of four very wide tiles.
  static const double _maxContentWidth = 920;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final employee = ref.watch(authControllerProvider).valueOrNull?.employee;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final theme = Theme.of(context);
    final name = employee?.name.split(' ').first ?? 'Dealer';

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;

    // One gutter for the whole page. The header used to sit at 20 while the
    // cards sat at 16, which is most of what made the page look off-square.
    final gutter = isWide ? 24.0 : 16.0;
    final side = width > _maxContentWidth + gutter * 2
        ? (width - _maxContentWidth) / 2
        : gutter;

    // Tiles are a fixed height rather than an aspect ratio so they cannot be
    // squeezed into an overflow on a narrow phone, and they grow with the
    // reader's text-size setting instead of clipping.
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final tileHeight = 150.0 * textScale;

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
              data: (data) {
                final metrics = <Widget>[
                  _MetricTile(
                    label: 'Hot leads',
                    caption: 'AI says ready to close',
                    value: data.hotLeadsCount,
                    color: AppColors.yamahaBlue,
                    icon: Icons.bolt_rounded,
                    featured: true,
                  ),
                  _MetricTile(
                    label: 'New',
                    caption: 'Not yet contacted',
                    value: data.newLeadsCount,
                    color: AppColors.statusNew,
                    icon: Icons.person_add_alt_1_rounded,
                  ),
                  _MetricTile(
                    label: 'Follow-ups',
                    caption: 'In conversation',
                    value: data.followUpLeadsCount,
                    color: AppColors.statusFollowUp,
                    icon: Icons.phone_forwarded_rounded,
                  ),
                  _MetricTile(
                    label: 'Closed',
                    caption: 'This month',
                    value: data.closedThisMonthCount,
                    color: AppColors.statusClosedWon,
                    icon: Icons.task_alt_rounded,
                  ),
                ];

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(side, 12, side, 0),
                      sliver: SliverToBoxAdapter(
                        child: FadeSlideIn(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
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
                              const SizedBox(width: 8),
                              // Nudged out to the gutter edge so the icon's own
                              // padding does not read as a ragged margin.
                              Padding(
                                padding: const EdgeInsets.only(top: 2, right: 4),
                                child: IconButton(
                                  tooltip: 'Notifications',
                                  onPressed: () =>
                                      context.push('/dealer/dashboard/notifications'),
                                  icon: Badge(
                                    label: Text('$unreadCount'),
                                    isLabelVisible: unreadCount > 0,
                                    child: const Icon(Icons.notifications_none_rounded),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Four tiles on one grid. They used to be two Rows with
                    // different flex ratios (6:5 then 1:2), so the seam between
                    // the columns moved from row to row.
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(side, 22, side, 0),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 4 : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: tileHeight,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => FadeSlideIn(
                            delay: Duration(milliseconds: 60 + index * 40),
                            child: metrics[index],
                          ),
                          childCount: metrics.length,
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(side, 12, side, 28),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 220),
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.north_east_rounded,
                                    color: AppColors.inkFaint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 260),
                            child: Text(
                              "Today's follow-ups",
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (data.todaysFollowups.isEmpty)
                            const EmptyState(
                              icon: Icons.check_circle_outline_rounded,
                              title: 'Inbox zero',
                              subtitle:
                                  'Nothing due today. New and overdue follow-ups land here.',
                            )
                          else
                            ...data.todaysFollowups.asMap().entries.map((entry) {
                              final item = entry.value;
                              final isLast =
                                  entry.key == data.todaysFollowups.length - 1;
                              return FadeSlideIn(
                                delay: Duration(milliseconds: 280 + entry.key * 40),
                                child: OpenListTile(
                                  showDivider: !isLast,
                                  onTap: () => context
                                      .push('/dealer/leads/${item.followup.leadId}'),
                                  child: Row(
                                    children: [
                                      AppIconWell(
                                        icon: item.followup.isOverdue
                                            ? Icons.warning_amber_rounded
                                            : Icons.event_available_rounded,
                                        size: 40,
                                        iconSize: 18,
                                        color: item.followup.isOverdue
                                            ? AppColors.hot
                                            : AppColors.yamahaBlue,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.leadCustomerName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '${item.followup.nextAction} · ${item.leadMobile}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        item.followup.isOverdue ? 'OVERDUE' : 'TODAY',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: item.followup.isOverdue
                                              ? AppColors.hot
                                              : AppColors.statusFollowUp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// One number on the dashboard grid.
///
/// Every tile shares the same anatomy — icon, number, label, caption — so the
/// grid lines up whatever the values are. The lead metric earns its emphasis
/// from the framed treatment and a LIVE tag rather than from being a different
/// size, which is what used to break the alignment.
class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.caption,
    required this.value,
    required this.color,
    required this.icon,
    this.featured = false,
  });

  final String label;
  final String caption;
  final int value;
  final Color color;
  final IconData icon;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      style: featured ? GlassStyle.framed : GlassStyle.soft,
      glow: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconWell(
                icon: icon,
                size: 34,
                iconSize: 16,
                color: color,
                filled: featured,
              ),
              if (featured) ...[
                const Spacer(),
                Text(
                  'LIVE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          AnimatedMetric(
            value: value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
