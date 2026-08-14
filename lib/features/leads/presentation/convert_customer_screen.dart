import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../incentives/data/incentives_providers.dart';
import '../../public/data/public_providers.dart';
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
  late final _registrationController = TextEditingController();

  /// Which bike goes into their garage. Seeded from the lead, because the
  /// dealer already recorded what they came in for; only editable when the lead
  /// never named one.
  String? _bikeModelId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _bikeModelId = widget.lead.interestedModelId;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(leadsRepositoryProvider).convertLead(
            widget.lead.id,
            email: _emailController.text.trim(),
            registrationNo: _registrationController.text.trim(),
            bikeModelId: _bikeModelId,
          );
      final customer = result.customer;

      invalidateLeadsData(ref, leadId: widget.lead.id);
      ref.invalidate(dashboardSummaryProvider);
      // The conversion just credited an incentive to whoever ran it.
      ref.invalidate(incentiveSummaryProvider);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result.invited ? 'Customer onboarded' : 'Customer created'),
          // Say whether they can actually sign in. A customer with no login looks
          // identical here but hears nothing when they ask for a code, so the
          // dealer has to learn it now, not from the customer later.
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${customer.name} is now a customer.'),
              const SizedBox(height: 12),
              if (result.invited)
                Text(
                  'They can sign in with ${customer.email} — a code is emailed '
                  'each time they log in.',
                  style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                )
              else ...[
                const Text(
                  'They cannot sign in yet.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.yamahaRed,
                  ),
                ),
                if (result.inviteError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    result.inviteError!,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                  ),
                ],
              ],
              if (result.vehicleId == null) ...[
                const SizedBox(height: 10),
                const Text(
                  'No bike was added — their garage is empty until one is linked.',
                  style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ],
          ),
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
            const SizedBox(height: 24),
            // The bike is what makes the customer account usable at all: with an
            // empty garage there is nothing to pair the OBD dongle to and no
            // subject for a service request.
            Text(
              'Their bike',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 10),
            _BikePicker(
              selectedId: _bikeModelId,
              fromLead: widget.lead.interestedModelId != null,
              onChanged: (id) => setState(() => _bikeModelId = id),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _registrationController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Registration number',
                hintText: 'MH12AB1234 — leave blank if not registered yet',
              ),
            ),
            const SizedBox(height: 24),
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

/// Picks the bike that goes into the new customer's garage.
///
/// When the lead already named a model this is a confirmation, not a question —
/// the dealer recorded it at enquiry and re-asking wastes their time. Only a
/// lead that never named one opens as an unanswered dropdown.
class _BikePicker extends ConsumerWidget {
  const _BikePicker({
    required this.selectedId,
    required this.fromLead,
    required this.onChanged,
  });

  final String? selectedId;
  final bool fromLead;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(publicModelsProvider);

    return models.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, _) => const Text(
        'Could not load the model list. The customer can be converted without a '
        'bike and have one added later.',
        style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
      ),
      data: (list) {
        final items = [...list]..sort((a, b) => a.displayName.compareTo(b.displayName));
        final valid = items.any((m) => m.id == selectedId) ? selectedId : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: valid,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Model'),
              hint: const Text('Select a model'),
              items: [
                for (final m in items)
                  DropdownMenuItem(value: m.id, child: Text(m.displayName)),
              ],
              onChanged: onChanged,
            ),
            if (valid != null && fromLead) ...[
              const SizedBox(height: 6),
              Text(
                'From their enquiry. Change it if they bought something else.',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.inkFaint),
              ),
            ],
          ],
        );
      },
    );
  }
}
