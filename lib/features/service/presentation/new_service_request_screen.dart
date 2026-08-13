import 'package:flutter/material.dart';

import '../../../core/config/design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/service_providers.dart';

const _serviceTypes = [
  'General service',
  'Engine noise',
  'Brake issue',
  'Electrical issue',
  'Warranty claim',
  'Other',
];

/// Route argument for the new-request form.
///
/// Exists so a ticket raised from the OBD dashboard can arrive pre-filled with
/// the captured diagnostics, while the plain "New request" button keeps passing
/// just a vehicle id.
class NewServiceRequestArgs {
  const NewServiceRequestArgs({
    required this.vehicleId,
    this.prefillType,
    this.prefillDescription,
    this.obdContext,
  });

  final String vehicleId;
  final String? prefillType;
  final String? prefillDescription;

  /// Raw readings, attached to the thread as their own message so the desk sees
  /// the evidence, and fed to the backend's AI triage.
  final String? obdContext;

  /// Accepts either shape of `GoRouterState.extra`: a bare vehicle id from the
  /// normal entry point, or a full args object from the dashboard.
  factory NewServiceRequestArgs.from(Object? extra) {
    if (extra is NewServiceRequestArgs) return extra;
    return NewServiceRequestArgs(vehicleId: extra as String);
  }
}

class NewServiceRequestScreen extends ConsumerStatefulWidget {
  const NewServiceRequestScreen({super.key, required this.args});

  final NewServiceRequestArgs args;

  @override
  ConsumerState<NewServiceRequestScreen> createState() => _NewServiceRequestScreenState();
}

class _NewServiceRequestScreenState extends ConsumerState<NewServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late String _type;
  DateTime? _preferredDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.args.prefillDescription ?? '');
    // Only honour a suggested type the dropdown actually offers.
    final suggested = widget.args.prefillType;
    _type = (suggested != null && _serviceTypes.contains(suggested))
        ? suggested
        : _serviceTypes.first;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final request = await ref.read(serviceRepositoryProvider).createRequest(
            vehicleId: widget.args.vehicleId,
            type: _type,
            description: _descriptionController.text.trim(),
            preferredDate: _preferredDate,
            obdContext: widget.args.obdContext,
          );
      ref.invalidate(serviceRequestsListProvider);
      if (!mounted) return;
      context.pushReplacement('/customer/service/${request.id}');
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
      appBar: AppBar(title: const Text('New service request')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Issue type'),
                items: _serviceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _serviceTypes.first),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Describe the issue *'),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Preferred date (optional)'),
                  child: Text(
                    _preferredDate == null ? 'Select a date' : DateFormat('d MMM yyyy').format(_preferredDate!),
                  ),
                ),
              ),
              if (widget.args.obdContext != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(Ds.rSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.memory, size: 16, color: Ds.inkSoft),
                          SizedBox(width: 6),
                          Text(
                            'Diagnostics attached',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.args.obdContext!,
                        style: const TextStyle(fontSize: 11, color: Ds.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
