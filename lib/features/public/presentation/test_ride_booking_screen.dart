import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../models/bike_model.dart';
import '../data/public_providers.dart';

class TestRideBookingScreen extends ConsumerStatefulWidget {
  const TestRideBookingScreen({super.key, this.preselectedModelId});

  final String? preselectedModelId;

  @override
  ConsumerState<TestRideBookingScreen> createState() => _TestRideBookingScreenState();
}

const _timeSlots = ['10:00 AM', '11:30 AM', '1:00 PM', '3:00 PM', '4:30 PM', '6:00 PM'];

class _TestRideBookingScreenState extends ConsumerState<TestRideBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  String? _selectedModelId;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _time = _timeSlots.first;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedModelId = widget.preselectedModelId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(publicRepositoryProvider).bookTestRide(
            bikeModelId: _selectedModelId!,
            name: _nameController.text.trim(),
            mobile: _mobileController.text.trim(),
            preferredDate: _date,
            preferredTime: _time,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test ride requested!'),
          content: const Text(
            "We've booked your slot and notified the nearest showroom. "
            "Our team will call you to confirm.",
          ),
          actions: [
            FilledButton(onPressed: () => context.pop(), child: const Text('Done')),
          ],
        ),
      );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(publicModelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Book a test ride')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Your name *'),
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
              AsyncValueWidget<List<BikeModel>>(
                value: modelsAsync,
                loading: const LinearProgressIndicator(),
                data: (models) => DropdownButtonFormField<String>(
                  initialValue: _selectedModelId,
                  decoration: const InputDecoration(labelText: 'Bike to test ride *'),
                  items: models
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedModelId = v),
                  validator: (v) => v == null ? 'Select a bike' : null,
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Preferred date'),
                  child: Text(DateFormat('d MMM yyyy').format(_date)),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _time,
                decoration: const InputDecoration(labelText: 'Preferred time'),
                items: _timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _time = v ?? _timeSlots.first),
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
                    : const Text('Request test ride'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
