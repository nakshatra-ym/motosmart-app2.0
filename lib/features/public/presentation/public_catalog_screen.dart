import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/app_visuals.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../models/bike_model.dart';
import '../../../models/enums.dart';
import '../data/public_providers.dart';

class PublicCatalogScreen extends ConsumerWidget {
  const PublicCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(publicModelsProvider);
    final theme = Theme.of(context);

    return AppPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yamaha Bikes', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                'Explore the lineup',
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.inkMuted, letterSpacing: 0.5),
              ),
            ],
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/exchange'),
                      icon: const Icon(Icons.currency_rupee_rounded, size: 18),
                      label: const Text('Exchange'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/book-test-ride'),
                      icon: const Icon(Icons.two_wheeler_rounded, size: 18),
                      label: const Text('Test ride'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...models.map((m) => _BikeListTile(model: m)),
            ],
          ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => context.push('/models/${model.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const AppIconWell(
                icon: Icons.two_wheeler_rounded,
                size: 56,
                iconSize: 26,
                filled: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model.displayName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      '${model.category} · ${model.engineCc}cc',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      priceText,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.yamahaBlue,
                        fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
