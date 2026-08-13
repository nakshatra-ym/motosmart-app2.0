import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/design.dart';

/// Sign-in. One field, one button, nothing else competing for attention.
///
/// Deliberately spare: this screen exists to be passed through, so it carries a
/// small mark, the single input, and the demo accounts kept visibly secondary.
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
                    // A small square mark rather than a logo lockup — quiet, and
                    // it does not pretend to be brand artwork we do not have.
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Ds.brand,
                        borderRadius: BorderRadius.circular(Ds.rSm + 2),
                      ),
                      child: const Icon(
                        Icons.two_wheeler,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: Ds.s6),
                    Text('Sign in', style: text.displaySmall),
                    const SizedBox(height: Ds.s2),
                    Text(
                      'We will send a one-time code to the email on your '
                      'account. Dealer staff and owners use the same sign-in.',
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: Ds.s8),
                    TextFormField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      style: text.titleMedium,
                      decoration: const InputDecoration(
                        labelText: 'Email or mobile',
                        hintText: 'you@dealership.com',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter the email or mobile on your account';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _sendOtp(),
                    ),
                    const SizedBox(height: Ds.s4),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _sendOtp,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send code'),
                    ),
                    const SizedBox(height: Ds.s10),
                    _DemoAccounts(onPick: (address) {
                      _identifierController.text = address;
                    }),
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

/// The seeded and real demo accounts, kept quiet and tappable so nobody has to
/// type a long address on a phone mid-demo. Tapping only fills the field — the
/// user still presses Send code, so nothing happens behind their back.
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Demo accounts', style: text.labelSmall),
            const SizedBox(width: Ds.s2),
            const Expanded(child: Divider(color: Ds.line, height: 1)),
          ],
        ),
        const SizedBox(height: Ds.s2),
        for (final account in const [
          ('Dealer', 'ijklmnop7417@gmail.com', true),
          ('Owner', 'darklord5156@gmail.com', true),
          ('Dealer', 'rohan@ymsli-demo.example', false),
          ('Owner', 'test.customer@ymsli-demo.example', false),
        ])
          InkWell(
            onTap: () => onPick(account.$2),
            borderRadius: BorderRadius.circular(Ds.rSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Ds.s2, horizontal: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      account.$1,
                      style: text.labelMedium?.copyWith(color: Ds.inkSoft),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      account.$2,
                      style: text.bodySmall?.copyWith(color: Ds.inkSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Ds.s2),
                  Icon(
                    account.$3 ? Icons.mail_outline : Icons.science_outlined,
                    size: 14,
                    color: account.$3 ? Ds.positive : Ds.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: Ds.s2),
        Text(
          'Real accounts get a code by email. Seeded ones accept any code.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}
