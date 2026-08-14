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

/// The showroom floor — what someone sees before they have an account.
///
/// There is no product photography in the catalogue, so the spec does the work
/// a photograph normally would: displacement is set as the largest element on
/// every card, in tabular figures, tinted by the family the machine belongs to.
/// A lineup you can read by number rather than a column of identical rows.
class PublicCatalogScreen extends ConsumerStatefulWidget {
  const PublicCatalogScreen({super.key});

  @override
  ConsumerState<PublicCatalogScreen> createState() => _PublicCatalogScreenState();
}

class _PublicCatalogScreenState extends ConsumerState<PublicCatalogScreen> {
  static const double _maxContentWidth = 900;

  /// Null means every family.
  String? _category;

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(publicModelsProvider);

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;
    final gutter = isWide ? 24.0 : 18.0;
    final side = width > _maxContentWidth + gutter * 2
        ? (width - _maxContentWidth) / 2
        : gutter;

    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);

    return AppPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: AsyncValueWidget<List<BikeModel>>(
            value: modelsAsync,
            onRetry: () => ref.invalidate(publicModelsProvider),
            data: (models) {
              final categories = <String>{for (final m in models) m.category}.toList()
                ..sort();
              final visible = _category == null
                  ? models
                  : models.where((m) => m.category == _category).toList();

              // The halo card is the dearest machine you can actually ride out
              // on, so the page opens on something bookable rather than on a
              // flagship the branch cannot supply.
              final featured = _pickFeatured(visible);
              final rest = visible.where((m) => m.id != featured?.id).toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, 8, side, 0),
                    sliver: SliverToBoxAdapter(
                      child: _Masthead(models: models, isWide: isWide),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, 26, side, 0),
                    sliver: SliverToBoxAdapter(
                      child: _FamilyBar(
                        categories: categories,
                        selected: _category,
                        onSelected: (value) => setState(() => _category = value),
                      ),
                    ),
                  ),
                  if (featured != null)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(side, 18, side, 0),
                      sliver: SliverToBoxAdapter(
                        child: FadeSlideIn(
                          child: _FeaturedCard(model: featured),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, 12, side, 32),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 2 : 1,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 108.0 * textScale,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => FadeSlideIn(
                          delay: Duration(milliseconds: 40 + index * 30),
                          child: _ModelCard(model: rest[index]),
                        ),
                        childCount: rest.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Dearest in stock; falls back to dearest overall when the whole family is
  /// sold out, so a filtered view still has something at its head.
  static BikeModel? _pickFeatured(List<BikeModel> models) {
    if (models.isEmpty) return null;
    final inStock =
        models.where((m) => m.stockStatus != StockStatus.outOfStock).toList();
    final pool = inStock.isEmpty ? models : inStock;
    return pool.reduce((a, b) => b.price > a.price ? b : a);
  }
}

/// Identity, the one-line pitch, and the two things a visitor can actually do.
class _Masthead extends StatelessWidget {
  const _Masthead({required this.models, required this.isWide});

  final List<BikeModel> models;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ccs = models.map((m) => m.engineCc).where((cc) => cc > 0).toList()..sort();
    final range = ccs.isEmpty ? null : '${ccs.first}–${ccs.last}cc';

    return FadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(child: _Wordmark()),
              const Spacer(),
              TextButton(
                // One sign-in for both roles — the token decides where you land,
                // so naming a role here turns customers away.
                onPressed: () => context.push('/login'),
                child: const Text('Sign in'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Find your next ride.',
            style: (isWide
                    ? theme.textTheme.displaySmall
                    : theme.textTheme.headlineLarge)
                ?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Book a test ride at your nearest Yamaha showroom, or find out what '
            'your current bike is worth. No account needed.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          if (range != null) ...[
            const SizedBox(height: 14),
            // Wrap, not Row: at a large system font size two fixed Texts and a
            // separator run past the edge.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${models.length} machines',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _dot(),
                Text(
                  range,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.inkMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _Actions(isWide: isWide),
        ],
      ),
    );
  }

  Widget _dot() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('·', style: TextStyle(color: AppColors.inkFaint)),
      );
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.yamahaBlue, Color(0xFF3B6BE0)],
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.two_wheeler_rounded, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'YAMAHA',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3.4,
                ),
          ),
        ),
      ],
    );
  }
}

/// The two real entry points. Test ride leads, because that is what a showroom
/// visitor came to do; valuing a trade-in is the second thought.
class _Actions extends StatelessWidget {
  const _Actions({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final book = FilledButton.icon(
      onPressed: () => context.push('/book-test-ride'),
      icon: const Icon(Icons.two_wheeler_rounded, size: 19),
      label: const Text('Book a test ride'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: AppColors.yamahaBlue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );

    final exchange = OutlinedButton.icon(
      onPressed: () => context.push('/exchange'),
      icon: const Icon(Icons.currency_rupee_rounded, size: 18),
      label: const Text('Value my bike'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
    );

    // Side by side only where both labels fit; stacked keeps the 48dp targets
    // and stops the text ellipsing on a narrow phone.
    if (isWide) {
      return Row(
        children: [
          Expanded(child: book),
          const SizedBox(width: 12),
          Expanded(child: exchange),
        ],
      );
    }
    return Column(
      children: [book, const SizedBox(height: 10), exchange],
    );
  }
}

class _FamilyBar extends StatelessWidget {
  const _FamilyBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(context, label: 'All', value: null),
          for (final c in categories) _chip(context, label: c, value: c),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, {required String label, required String? value}) {
    final isSelected = selected == value;
    final tint = value == null ? AppColors.yamahaBlue : _familyColor(value);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: isSelected ? tint : AppColors.inkMuted,
        ),
        backgroundColor: Colors.transparent,
        selectedColor: tint.withValues(alpha: 0.16),
        side: BorderSide(
          color: isSelected ? tint.withValues(alpha: 0.55) : AppColors.border,
        ),
      ),
    );
  }
}

/// One machine, given room. Same anatomy as the small cards, set larger.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.model});

  final BikeModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = _familyColor(model.category);

    return GlassPanel(
      style: GlassStyle.framed,
      glow: tint,
      onTap: () => context.push('/models/${model.id}'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Displacement(cc: model.engineCc, tint: tint, size: _PlateSize.large),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.category.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tint,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      model.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StockChip(status: model.stockStatus),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Price(value: model.price, large: true)),
              const SizedBox(width: 12),
              Text(
                'View',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 18, color: tint),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.model});

  final BikeModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = _familyColor(model.category);

    return GlassPanel(
      onTap: () => context.push('/models/${model.id}'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _Displacement(cc: model.engineCc, tint: tint, size: _PlateSize.small),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  model.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: tint),
                ),
                const SizedBox(height: 8),
                _Price(value: model.price),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StockChip(status: model.stockStatus, compact: true),
        ],
      ),
    );
  }
}

enum _PlateSize { small, large }

/// Displacement, set as the card's image.
///
/// Tabular figures so 125 and 321 occupy the same width and the plates line up
/// down the page — the lineup reads as a ladder rather than a ragged list.
class _Displacement extends StatelessWidget {
  const _Displacement({required this.cc, required this.tint, required this.size});

  final int cc;
  final Color tint;
  final _PlateSize size;

  @override
  Widget build(BuildContext context) {
    final large = size == _PlateSize.large;
    final box = large ? 86.0 : 62.0;

    return Container(
      width: box,
      height: box,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(large ? 20 : 16),
        color: tint.withValues(alpha: 0.12),
        border: Border.all(color: tint.withValues(alpha: 0.32)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$cc',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: large ? 34 : 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.4,
                height: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'CC',
            style: TextStyle(
              color: tint,
              fontSize: large ? 11 : 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.value, this.large = false});

  final double value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: large ? 24 : 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (large)
          Text(
            'ex-showroom',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.inkFaint),
          ),
      ],
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.status, this.compact = false});

  final StockStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Availability stays on its own semantic scale, separate from the family
    // hue, so "sold out" never reads as a colour the lineup uses for identity.
    final color = switch (status) {
      StockStatus.inStock => AppColors.statusClosedWon,
      StockStatus.limited => AppColors.warm,
      StockStatus.outOfStock => AppColors.statusClosedLost,
    };

    if (compact) {
      return Tooltip(
        message: status.label,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 7),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Family identity. Scooters, street bikes and sport bikes are three different
/// things to shop for, and the colour is the fastest way to tell them apart on
/// a page with no photographs.
Color _familyColor(String category) => switch (category.toLowerCase()) {
      'scooter' => AppColors.violet,
      'street' => AppColors.yamahaBlue,
      'sport' => AppColors.yamahaRed,
      _ => AppColors.inkMuted,
    };
