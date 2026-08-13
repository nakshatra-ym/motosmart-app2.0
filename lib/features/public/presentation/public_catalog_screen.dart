import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../models/bike_model.dart';
import '../../../models/enums.dart';
import '../data/public_providers.dart';

class PublicCatalogScreen extends ConsumerWidget {
  const PublicCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(publicModelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yamaha Bikes'),
        actions: [
          TextButton(
            onPressed: () => context.push('/login'),
            child: const Text('Dealer login'),
          ),
        ],
      ),
      body: AsyncValueWidget<List<BikeModel>>(
        value: modelsAsync,
        onRetry: () => ref.invalidate(publicModelsProvider),
        data: (models) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/exchange'),
                    icon: const Icon(Icons.currency_rupee, size: 18),
                    label: const Text('Exchange value'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/book-test-ride'),
                    icon: const Icon(Icons.two_wheeler, size: 18),
                    label: const Text('Book test ride'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...models.map((m) => _BikeListTile(model: m)),
          ],
        ),
      ),
    );
  }
}

class _BikeListTile extends StatelessWidget {
  const _BikeListTile({required this.model});

  final BikeModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceText = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(model.price);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => context.push('/models/${model.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.yamahaBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.yamahaBlue.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(Icons.two_wheeler, color: AppColors.yamahaBlue, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model.displayName, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${model.category} · ${model.engineCc}cc',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceText,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.yamahaBlue,
                      ),
                    ),
                  ],
                ),
              ),
              _StockBadge(status: model.stockStatus),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StockStatus.inStock => AppColors.statusClosedWon,
      StockStatus.limited => AppColors.warm,
      StockStatus.outOfStock => AppColors.statusClosedLost,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
