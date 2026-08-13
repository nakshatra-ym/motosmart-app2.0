import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../models/exchange_estimate.dart';
import '../data/public_providers.dart';

class ExchangeValueScreen extends ConsumerStatefulWidget {
  const ExchangeValueScreen({super.key});

  @override
  ConsumerState<ExchangeValueScreen> createState() => _ExchangeValueScreenState();
}

class _ExchangeValueScreenState extends ConsumerState<ExchangeValueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  String _condition = 'Good';
  bool _isSubmitting = false;
  ExchangeEstimate? _result;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _estimate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _result = null;
    });
    try {
      final result = await ref.read(publicRepositoryProvider).estimateExchangeValue(
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            year: int.parse(_yearController.text.trim()),
            condition: _condition,
          );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exchange value estimator')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Current bike brand *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Current bike model *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Purchase year *'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final year = int.tryParse(v?.trim() ?? '');
                  if (year == null || year < 1990 || year > DateTime.now().year) {
                    return 'Enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: const ['Excellent', 'Good', 'Fair', 'Poor']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v ?? 'Good'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _estimate,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Get estimate'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('Estimated exchange value', style: TextStyle(color: AppColors.inkMuted)),
                        const SizedBox(height: 8),
                        Text(
                          NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
                              .format(_result!.estimatedValue),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _result!.note,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
