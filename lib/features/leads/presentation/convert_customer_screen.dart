import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/leads_providers.dart';
import '../../../models/lead.dart';

class ConvertCustomerScreen extends ConsumerWidget {
  const ConvertCustomerScreen({super.key, required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsync = ref.watch(leadDetailProvider(leadId));

    return Scaffold(
      appBar: AppBar(title: const Text('Convert to customer')),
      body: AsyncValueWidget<Lead>(
        value: leadAsync,
        onRetry: () => ref.invalidate(leadDetailProvider(leadId)),
        data: (lead) => _ConvertForm(lead: lead),
      ),
    );
  }
}

class _ConvertForm extends ConsumerStatefulWidget {
  const _ConvertForm({required this.lead});

  final Lead lead;

  @override
  ConsumerState<_ConvertForm> createState() => _ConvertFormState();
}

class _ConvertFormState extends ConsumerState<_ConvertForm> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final customer = await ref
          .read(leadsRepositoryProvider)
          .convertLead(widget.lead.id, email: _emailController.text.trim());

      invalidateLeadsData(ref, leadId: widget.lead.id);
      ref.invalidate(dashboardSummaryProvider);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Customer onboarded'),
          content: Text('${customer.name} is now a customer (ID: ${customer.id}).'),
          actions: [
            FilledButton(onPressed: () => context.pop(), child: const Text('Done')),
          ],
        ),
      );
      if (!mounted) return;
      context.go('/dealer/leads/${widget.lead.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(lead.mobile, style: const TextStyle(color: AppColors.inkMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add an email so this customer can be onboarded for OTP login and vehicle/service access.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Convert to customer'),
            ),
          ],
        ),
      ),
    );
  }
}
