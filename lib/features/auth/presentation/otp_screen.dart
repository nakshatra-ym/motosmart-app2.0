import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/mock_auth_repository.dart';
import '../../../core/config/theme.dart';
import '../../../models/enums.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.identifier});

  final String identifier;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).confirmOtp(
            identifier: widget.identifier,
            otp: _otpController.text.trim(),
          );
      // The redirect guard would eventually catch this too, but this screen
      // was reached via push() on top of the public catalog/login stack, so
      // navigate explicitly rather than waiting on a refreshListenable-driven
      // redirect for a non-top-level route.
      if (!mounted) return;
      final role = ref.read(authControllerProvider).valueOrNull?.role;
      context.go(role == UserRole.customer ? '/customer/home' : '/dealer/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(widget.identifier);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.sms_outlined, size: 48, color: AppColors.yamahaBlue),
                    const SizedBox(height: 12),
                    Text(
                      'Enter the OTP sent to',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      widget.identifier,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      decoration: const InputDecoration(counterText: ''),
                      validator: (value) {
                        if (value == null || value.trim().length != 6) {
                          return 'Enter the 6-digit OTP';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Demo OTP: ${MockAuthRepository.demoOtp}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _verify,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Verify & Continue'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isResending ? null : _resend,
                      child: Text(_isResending ? 'Resending…' : 'Resend OTP'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
