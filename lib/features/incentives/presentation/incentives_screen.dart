import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../models/employee_incentive.dart';
import '../data/incentives_providers.dart';

/// What the signed-in employee earned this month, and what earned it.
///
/// Deliberately personal: it shows this employee's row only, never the rest of
/// the branch. Incentives are attributed to whoever performed the act — the
/// person who converted the lead, the person who closed the ticket — so a
/// roster here would misread as everyone sharing the same pot.
class IncentivesScreen extends ConsumerWidget {
  const IncentivesScreen({super.key});

  Future<void> _pickMonth(BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 2),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      ref.read(incentivesMonthProvider.notifier).state = DateTime(picked.year, picked.month);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(incentivesMonthProvider);
    final mine = ref.watch(myIncentiveProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My incentives'),
        actions: [
          TextButton(
            onPressed: () => _pickMonth(context, ref, month),
            child: Text(
              DateFormat('MMM yyyy').format(month),
              style: const TextStyle(color: AppColors.ink),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(incentiveSummaryProvider),
        child: AsyncValueWidget<EmployeeIncentive?>(
          value: mine,
          onRetry: () => ref.invalidate(incentiveSummaryProvider),
          data: (incentive) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _EarningsHero(
                amount: incentive?.totalIncentive ?? 0,
                month: month,
                currency: currency,
              ),
              const SizedBox(height: 24),
              Text(
                'How you earned it',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 12),
              _EarnRow(
                icon: Icons.handshake_outlined,
                label: 'Customers converted',
                count: incentive?.conversionsCount ?? 0,
                paid: true,
              ),
              _EarnRow(
                icon: Icons.build_circle_outlined,
                label: 'Service tickets closed',
                count: incentive?.ticketsResolvedCount ?? 0,
                paid: true,
              ),
              _EarnRow(
                icon: Icons.two_wheeler_outlined,
                label: 'Test rides completed',
                count: incentive?.testRidesCount ?? 0,
                paid: true,
              ),
              const SizedBox(height: 20),
              _EarnRow(
                icon: Icons.person_add_alt_outlined,
                label: 'Leads handled',
                count: incentive?.leadsCount ?? 0,
                paid: false,
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Leads are counted, not paid. A lead earns only once you close '
                  'it — a lost or still-open lead pays nothing.',
                  style: TextStyle(fontSize: 12, color: AppColors.inkFaint, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningsHero extends StatelessWidget {
  const _EarningsHero({
    required this.amount,
    required this.month,
    required this.currency,
  });

  final double amount;
  final DateTime month;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.glassBorder),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16213A), Color(0xFF0E121B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You earned in ${DateFormat('MMMM').format(month)}',
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              currency.format(amount),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  const _EarnRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.paid,
  });

  final IconData icon;
  final String label;
  final int count;

  /// Whether this act pays. False rows are context, not earnings, and stay grey
  /// however high the count climbs.
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final earned = paid && count > 0;
    final tint = earned ? AppColors.accent : AppColors.inkFaint;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: earned ? tint.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: tint),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: earned ? AppColors.ink : AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: earned ? tint : AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}
