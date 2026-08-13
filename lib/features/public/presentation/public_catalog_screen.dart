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
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: FadeSlideIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LINEUP',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.yamahaBlue,
                                letterSpacing: 2.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Yamaha Bikes',
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Dealer login'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AsyncValueWidget<List<BikeModel>>(
                  value: modelsAsync,
                  onRetry: () => ref.invalidate(publicModelsProvider),
                  data: (models) => ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    children: [
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: Row(
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
                      ),
                      const SizedBox(height: 16),
                      ...models.asMap().entries.map((e) {
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 80 + e.key * 40),
                          child: _BikeTile(model: e.value),
                        );
                      }),
                    ],
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

class _BikeTile extends StatelessWidget {
  const _BikeTile({required this.model});

  final BikeModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceText = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(model.price);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        onTap: () => context.push('/models/${model.id}'),
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
                  Text('${model.category} · ${model.engineCc}cc', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    priceText,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.accent,
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
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
