import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/api_auth_repository.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/mock_auth_repository.dart';
import '../../../core/config/env.dart';
import '../../../core/config/design.dart';
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Ds.surface,
      appBar: AppBar(backgroundColor: Ds.surface, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Ds.s6, 0, Ds.s6, Ds.s6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Ds.formMax),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Enter code', style: text.displaySmall),
                    const SizedBox(height: Ds.s2),
                    // The address is the one fact that matters here, so it reads
                    // as part of the sentence rather than as a separate field.
                    Text.rich(
                      TextSpan(
                        style: text.bodyMedium,
                        children: [
                          const TextSpan(text: 'Sent to '),
                          TextSpan(
                            text: widget.identifier,
                            style: text.bodyMedium?.copyWith(
                              color: Ds.ink,
                              fontVariations: const [FontVariation('wght', 600)],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Ds.s8),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      // Cognito's passwordless email codes are 8 digits; the
                      // seeded demo accounts use a 6-digit one. Capping at 6
                      // silently truncated every real code.
                      maxLength: _maxOtpLength,
                      textAlign: TextAlign.center,
                      // Wide tracking and tabular digits: a code is read back in
                      // groups, and the field must not shift as it fills.
                      style: Ds.figure(30, weight: 620).copyWith(letterSpacing: 10),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '––––––––',
                        contentPadding: EdgeInsets.symmetric(vertical: Ds.s5),
                      ),
                      validator: (value) {
                        final otp = value?.trim() ?? '';
                        if (otp.length < _minOtpLength || otp.length > _maxOtpLength) {
                          return 'Enter the $_minOtpLength–$_maxOtpLength digit code we sent you';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: Ds.s3),
                    // Only the demo accounts accept the canned code; a real
                    // account's code arrives by email, so advertising it there
                    // would just be wrong.
                    Row(
                      children: [
                        Icon(
                          _acceptsDemoOtp
                              ? Icons.science_outlined
                              : Icons.mail_outline,
                          size: 14,
                          color: _acceptsDemoOtp ? Ds.inkMuted : Ds.positive,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _acceptsDemoOtp
                                ? 'Seeded account — the code is ${MockAuthRepository.demoOtp}.'
                                : 'Check spam if it has not arrived.',
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Ds.s6),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _verify,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Verify'),
                    ),
                    const SizedBox(height: Ds.s2),
                    TextButton(
                      onPressed: _isResending ? null : _resend,
                      child: Text(_isResending ? 'Sending…' : 'Send a new code'),
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
