import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/app_visuals.dart';
import '../../../core/widgets/shimmer.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final identifier = _identifierController.text.trim();
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(identifier);
      if (!mounted) return;
      context.push('/otp', extra: identifier);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const FadeSlideIn(child: MotospotMark()),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Dealer & customer access',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: GlassPanel(
                        glow: AppColors.yamahaBlue,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Sign in',
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Drop your work email or mobile — we’ll beam an OTP.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: _identifierController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(color: AppColors.ink),
                                decoration: const InputDecoration(
                                  labelText: 'Work email or mobile number',
                                  prefixIcon: Icon(Icons.alternate_email_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter your email or mobile number';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _sendOtp(),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : _sendOtp,
                                child: _isSubmitting
                                    ? const SoftLoader(size: 20, color: Colors.white)
                                    : const Text('Continue with OTP'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: GlassPanel(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Real OTP (email):\n'
                          'Dealer — ijklmnop7417@gmail.com\n'
                          'Customer — darklord5156@gmail.com\n\n'
                          'Demo (any OTP):\n'
                          'Dealer — rohan@ymsli-demo.example\n'
                          'Customer — test.customer@ymsli-demo.example',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                            height: 1.45,
                          ),
                        ),
                      ),
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
