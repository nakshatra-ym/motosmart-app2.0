import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/app_visuals.dart';

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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // Atmospheric brand plane
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.brandInk,
                    const Color(0xFF121A2E),
                    AppColors.canvas,
                    AppColors.canvas,
                  ],
                  stops: const [0.0, 0.5, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -size.width * 0.2,
            right: -size.width * 0.25,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.yamahaBlue.withValues(alpha: 0.45),
                    AppColors.yamahaBlue.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.18,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.yamahaRed.withValues(alpha: 0.28),
                    AppColors.yamahaRed.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      const MotospotMark(light: true),
                      const SizedBox(height: 10),
                      Text(
                        'Dealer & customer sign-in',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome back',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter your work email or mobile to get an OTP.',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _identifierController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
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
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Send OTP'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppColors.border),
                        ),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
