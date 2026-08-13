import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/design.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../models/bike_model.dart';
import '../../../models/enums.dart';
import '../data/public_providers.dart';

/// The guest landing: the range, browsable without an account.
///
/// A visitor arrives wanting one of three things — see the bikes, find out what
/// their old one is worth, or book a ride. So the screen opens with a short line
/// saying what this is, puts those two actions in reach, and then gets out of the
/// way and lists bikes. No hero image, no marketing block: the bikes are the
/// content and they start almost immediately.
class PublicCatalogScreen extends ConsumerWidget {
  const PublicCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(publicModelsProvider);
    final pad = Ds.pagePad(context);

    return Scaffold(
      body: AsyncValueWidget<List<BikeModel>>(
        value: modelsAsync,
        onRetry: () => ref.invalidate(publicModelsProvider),
        data: (models) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 132,
              backgroundColor: Ds.surface,
              surfaceTintColor: Colors.transparent,
              // Collapses to a plain title bar as the list scrolls under it.
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(
                  left: pad.left,
                  right: pad.right,
                  bottom: Ds.s3,
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yamaha',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Text(
                      'Prices, exchange value and test rides.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Sign in'),
                ),
                SizedBox(width: pad.right - Ds.s2),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad.left, Ds.s2, pad.right, 0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Ds.readingMax),
                    child: const _QuickActions(),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad.left, Ds.s6, pad.right, Ds.s10),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Ds.readingMax),
                    child: _ModelList(models: models),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exchange value and test ride, as the two tonal actions above the list.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.published_with_changes,
            label: 'Exchange value',
            caption: 'Value your current bike',
            onTap: () => context.push('/exchange'),
          ),
        ),
        const SizedBox(width: Ds.s3),
        Expanded(
          child: _ActionTile(
            icon: Icons.event_available_outlined,
            label: 'Book a test ride',
            caption: 'Pick a bike and a day',
            onTap: () => context.push('/book-test-ride'),
            primary: true,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  /// The one action worth carrying the brand colour.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fg = primary ? Colors.white : Ds.ink;

    return Material(
      color: primary ? Ds.brand : Ds.surfaceRaised,
      borderRadius: BorderRadius.circular(Ds.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Ds.rMd),
        child: Container(
          padding: const EdgeInsets.all(Ds.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Ds.rMd),
            border: primary ? null : Border.all(color: Ds.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: primary ? Colors.white : Ds.brand),
              const SizedBox(height: Ds.s3),
              Text(
                label,
                style: text.titleSmall?.copyWith(color: fg),
                maxLines: 2,
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: text.bodySmall?.copyWith(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.75)
                      : Ds.inkMuted,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The range. One column on a phone, two on a tablet.
class _ModelList extends StatelessWidget {
  const _ModelList({required this.models});

  final List<BikeModel> models;

  @override
  Widget build(BuildContext context) {
    final twoUp = MediaQuery.sizeOf(context).width >= Ds.compactMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('All models', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: Ds.s2),
            Text(
              '${models.length}',
              style: Ds.figure(13, weight: 640, color: Ds.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: Ds.s3),
        if (!twoUp)
          for (final m in models)
            Padding(
              padding: const EdgeInsets.only(bottom: Ds.s3),
              child: _BikeCard(model: m),
            )
        else
          // A plain wrap of two columns: no aspect-ratio grid, so a long model
          // name grows its own card instead of clipping.
          LayoutBuilder(
            builder: (context, constraints) {
              final w = (constraints.maxWidth - Ds.s3) / 2;
              return Wrap(
                spacing: Ds.s3,
                runSpacing: Ds.s3,
                children: [
                  for (final m in models)
                    SizedBox(width: w, child: _BikeCard(model: m)),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// One bike: name, spec, price, and whether it can be had today.
class _BikeCard extends StatelessWidget {
  const _BikeCard({required this.model});

  final BikeModel model;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final priceText = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(model.price);

    return Material(
      color: Ds.surfaceRaised,
      borderRadius: BorderRadius.circular(Ds.rMd),
      child: InkWell(
        onTap: () => context.push('/models/${model.id}'),
        borderRadius: BorderRadius.circular(Ds.rMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Ds.rMd),
            border: Border.all(color: Ds.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A tinted panel where the bike photograph belongs. The silhouette
              // is honest about being a placeholder rather than a fake render;
              // real imagery drops in here without changing the layout.
              Container(
                height: 108,
                decoration: BoxDecoration(
                  color: Ds.surfaceSunken,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Ds.rMd - 1),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.two_wheeler,
                        size: 44,
                        color: Ds.lineStrong,
                      ),
                    ),
                    Positioned(
                      top: Ds.s2,
                      left: Ds.s2,
                      child: _StockBadge(status: model.stockStatus),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Ds.s3 + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.displayName,
                      style: text.titleMedium?.copyWith(color: Ds.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${model.category} · ${model.engineCc}cc',
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Ds.s3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ex-showroom',
                                style: text.labelSmall,
                              ),
                              const SizedBox(height: 1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  priceText,
                                  style: Ds.figure(17, weight: 660),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          size: 17,
                          color: Ds.inkMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Availability, as a small tonal chip over the image panel.
class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StockStatus.inStock => Ds.positive,
      StockStatus.limited => Ds.caution,
      StockStatus.outOfStock => Ds.neutral,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Ds.s2, vertical: 3),
      decoration: BoxDecoration(
        color: Ds.surfaceRaised,
        borderRadius: BorderRadius.circular(Ds.rPill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(status.label, style: Ds.label(color: color, size: 10.5)),
        ],
      ),
    );
  }
}
