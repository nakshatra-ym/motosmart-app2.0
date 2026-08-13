import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/api_auth_repository.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/mock_auth_repository.dart';
import '../../../core/config/env.dart';
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

  /// Cognito emails an 8-digit code; the seeded demo accounts use 6.
  static const _minOtpLength = 6;
  static const _maxOtpLength = 8;

  /// True when this sign-in takes the canned code rather than an emailed one:
  /// either the whole app is on mock data, or this is a seeded demo identifier.
  bool get _acceptsDemoOtp =>
      Env.useMockData || ApiAuthRepository.usesDevShortcut(widget.identifier);

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
                      // Cognito's passwordless email codes are 8 digits; the
                      // seeded demo accounts use a 6-digit one. Capping at 6
                      // silently truncated every real code.
                      maxLength: _maxOtpLength,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 6),
                      decoration: const InputDecoration(counterText: ''),
                      validator: (value) {
                        final otp = value?.trim() ?? '';
                        if (otp.length < _minOtpLength || otp.length > _maxOtpLength) {
                          return 'Enter the $_minOtpLength–$_maxOtpLength digit code we sent you';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: 8),
                    // Only the demo accounts accept the canned code; a real
                    // account's code arrives by email, so advertising it there
                    // would just be wrong.
                    if (_acceptsDemoOtp)
                      Text(
                        'Demo OTP: ${MockAuthRepository.demoOtp}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black45, fontSize: 12),
                      )
                    else
                      const Text(
                        'The code was emailed to you — check spam too.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black45, fontSize: 12),
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
