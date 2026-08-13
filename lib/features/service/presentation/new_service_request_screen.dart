import 'package:flutter/material.dart';
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

class NewServiceRequestScreen extends ConsumerStatefulWidget {
  const NewServiceRequestScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<NewServiceRequestScreen> createState() => _NewServiceRequestScreenState();
}

class _NewServiceRequestScreenState extends ConsumerState<NewServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _type = _serviceTypes.first;
  DateTime? _preferredDate;
  bool _isSubmitting = false;

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
            vehicleId: widget.vehicleId,
            type: _type,
            description: _descriptionController.text.trim(),
            preferredDate: _preferredDate,
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
