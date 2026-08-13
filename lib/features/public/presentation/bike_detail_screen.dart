import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../models/bike_model.dart';
import '../data/public_providers.dart';

class BikeDetailScreen extends ConsumerWidget {
  const BikeDetailScreen({super.key, required this.modelId});

  final String modelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelAsync = ref.watch(publicModelDetailProvider(modelId));

    return Scaffold(
      appBar: AppBar(title: const Text('Bike details')),
      body: AsyncValueWidget<BikeModel>(
        value: modelAsync,
        onRetry: () => ref.invalidate(publicModelDetailProvider(modelId)),
        data: (model) {
          final priceText =
              NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
                  .format(model.price);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.two_wheeler,
                      size: 72, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                model.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                model.category,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Text(
                priceText,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SpecRow(label: 'Engine', value: '${model.engineCc} cc'),
                      _SpecRow(label: 'Stock status', value: model.stockStatus.label),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/book-test-ride', extra: model.id),
                icon: const Icon(Icons.two_wheeler),
                label: const Text('Book a test ride'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.push('/exchange'),
                icon: const Icon(Icons.currency_rupee),
                label: const Text('Check exchange value'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
