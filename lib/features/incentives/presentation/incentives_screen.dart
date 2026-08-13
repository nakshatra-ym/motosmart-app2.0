import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/employee_incentive.dart';
import '../data/incentives_providers.dart';

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
    final summaryAsync = ref.watch(incentiveSummaryProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incentives'),
        actions: [
          TextButton(
            onPressed: () => _pickMonth(context, ref, month),
            child: Text(DateFormat('MMM yyyy').format(month), style: const TextStyle(color: AppColors.ink)),
          ),
        ],
      ),
      body: AsyncValueWidget<IncentiveSummary>(
        value: summaryAsync,
        onRetry: () => ref.invalidate(incentiveSummaryProvider),
        data: (summary) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppColors.yamahaBlue,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Dealer total this month', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(
                        currency.format(summary.dealerTotal),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (summary.byEmployee.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: EmptyState(icon: Icons.emoji_events_outlined, title: 'No incentive data yet'),
                )
              else
                ...summary.byEmployee.map((e) => _EmployeeIncentiveCard(incentive: e, currency: currency)),
            ],
          );
        },
      ),
    );
  }
}

class _EmployeeIncentiveCard extends StatelessWidget {
  const _EmployeeIncentiveCard({required this.incentive, required this.currency});

  final EmployeeIncentive incentive;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(incentive.employeeName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Text(
                  currency.format(incentive.totalIncentive),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.yamahaRed),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(label: 'Leads', value: incentive.leadsCount),
                const SizedBox(width: 8),
                _StatChip(label: 'Conversions', value: incentive.conversionsCount),
                const SizedBox(width: 8),
                _StatChip(label: 'Test rides', value: incentive.testRidesCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 11)),
    );
  }
}
