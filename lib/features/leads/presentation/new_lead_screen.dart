import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/mic_record_button.dart';
import '../../../models/bike_model.dart';
import '../../../models/enums.dart';
import '../data/leads_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';

class NewLeadScreen extends ConsumerStatefulWidget {
  const NewLeadScreen({super.key});

  @override
  ConsumerState<NewLeadScreen> createState() => _NewLeadScreenState();
}

class _NewLeadScreenState extends ConsumerState<NewLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _currentBikeController = TextEditingController();
  final _notesController = TextEditingController();

  LeadSource _source = LeadSource.walkIn;
  String? _interestedModelId;
  DateTime? _tentativeDate;
  bool _runAiClassification = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _currentBikeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _tentativeDate = picked);
  }

  Future<bool> _confirmDuplicateIfAny(String mobile) async {
    final isDuplicate = await ref.read(leadsRepositoryProvider).hasDuplicateMobile(mobile);
    if (!isDuplicate || !mounted) return true;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate mobile number'),
        content: const Text(
          'Another lead already uses this mobile number. Do you want to save this enquiry anyway?',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => context.pop(true), child: const Text('Save anyway')),
        ],
      ),
    );
    return proceed ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = _mobileController.text.trim();
    final canProceed = await _confirmDuplicateIfAny(mobile);
    if (!canProceed) return;

    setState(() => _isSubmitting = true);
    try {
      final lead = await ref.read(leadsRepositoryProvider).createLead(
            customerName: _nameController.text.trim(),
            mobile: mobile,
            source: _source,
            interestedModelId: _interestedModelId,
            currentBike: _currentBikeController.text.trim().isEmpty
                ? null
                : _currentBikeController.text.trim(),
            tentativePurchaseDate: _tentativeDate,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );

      if (_runAiClassification) {
        try {
          await ref.read(leadsRepositoryProvider).classifyLead(lead.id);
        } catch (_) {
          // AI classification is best-effort; the lead is already saved.
        }
      }

      invalidateLeadsData(ref, leadId: lead.id);
      ref.invalidate(dashboardSummaryProvider);

      if (!mounted) return;
      context.pushReplacement('/dealer/leads/${lead.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bikeModelsAsync = ref.watch(bikeModelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New enquiry')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Customer name *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile number *'),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) return 'Enter a 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<LeadSource>(
                initialValue: _source,
                decoration: const InputDecoration(labelText: 'Enquiry source'),
                items: LeadSource.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) => setState(() => _source = v ?? LeadSource.walkIn),
              ),
              const SizedBox(height: 14),
              AsyncValueWidget<List<BikeModel>>(
                value: bikeModelsAsync,
                loading: const LinearProgressIndicator(),
                data: (models) => DropdownButtonFormField<String>(
                  initialValue: _interestedModelId,
                  decoration: const InputDecoration(labelText: 'Interested model'),
                  items: models
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _interestedModelId = v),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _currentBikeController,
                decoration: const InputDecoration(labelText: 'Current bike (if any)'),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tentative purchase date'),
                  child: Row(
                    children: [
                      Text(
                        _tentativeDate == null
                            ? 'Select a date'
                            : DateFormat('d MMM yyyy').format(_tentativeDate!),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                  ),
                  MicRecordButton(controller: _notesController),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Run AI intent classification on save'),
                subtitle: const Text('Tags this lead HOT / WARM / COLD automatically'),
                value: _runAiClassification,
                onChanged: (v) => setState(() => _runAiClassification = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _save,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save enquiry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
