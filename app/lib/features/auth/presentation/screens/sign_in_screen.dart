import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_theme.dart';

/// Minimal email/password sign-in, enough to obtain a session so RLS-gated
/// staff data can be read. The full Authentication module (invites, sign-up,
/// password reset) is a separate piece of work, not built here.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(supabaseClientProvider).auth.signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (error) {
      setState(() => _error = 'Sign-in failed: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 12,
                shadowColor: Colors.black45,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(gradient: AppTheme.heroGradient, shape: BoxShape.circle),
                          child: const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'DARE TO CHANGE (D2C)',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'SMK Sungai Damit',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                          obscureText: true,
                          validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
