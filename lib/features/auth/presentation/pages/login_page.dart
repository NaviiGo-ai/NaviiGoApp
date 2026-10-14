import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/entry_frame.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(authControllerProvider).status == AuthStatus.loading ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final controller = ref.read(authControllerProvider.notifier);
    // Password whitespace is significant; never trim it.
    final success = _signUp
        ? await controller.register(
            _email.text.trim(),
            _password.text,
            _name.text.trim(),
          )
        : await controller.signIn(_email.text.trim(), _password.text);
    if (success) TextInput.finishAutofillContext();
    // Firebase auth + confirmed preferences drive the router, not this form.
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.status == AuthStatus.loading;
    return EntryFrame(
      eyebrow: 'NAVIIGO · EVERY JOURNEY HAS A STORY',
      title: _signUp
          ? 'Your next chapter starts here.'
          : 'Welcome back, traveller.',
      subtitle:
          'Travel should feel like an experience, not a project to manage.',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/brand/varanasi-dawn-hero.jpg',
            height: 140,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 80,
              child: Icon(
                Icons.explore_outlined,
                color: AppColors.teal,
                size: 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: loading
              ? null
              : () => ref
                    .read(authControllerProvider.notifier)
                    .signInWithGoogle(),
          icon: const Icon(Icons.login_rounded),
          label: const Text('Continue with Google'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: Text('or continue with email')),
        ),
        AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_signUp) ...[
                  TextFormField(
                    controller: _name,
                    enabled: !loading,
                    decoration: const InputDecoration(labelText: 'Your name'),
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Enter your name.' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email,
                  enabled: !loading,
                  decoration: const InputDecoration(labelText: 'Email address'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v ?? '').trim().contains('@')
                      ? null
                      : 'Enter a valid email address.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  enabled: !loading,
                  obscureText: _obscure,
                  autofillHints: [
                    _signUp
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) => (v ?? '').isEmpty
                      ? 'Enter your password.'
                      : _signUp && v!.length < 6
                      ? 'Use at least 6 characters.'
                      : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (auth.errorMessage != null) EntryMessage(auth.errorMessage!),
                const SizedBox(height: 24),
                if (loading)
                  const LinearProgressIndicator(semanticsLabel: 'Signing in'),
                ElevatedButton(
                  onPressed: loading ? null : _submit,
                  child: Text(
                    loading
                        ? 'Please wait…'
                        : _signUp
                        ? 'Create account'
                        : 'Sign in',
                  ),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          ref
                              .read(authControllerProvider.notifier)
                              .clearError();
                          setState(() => _signUp = !_signUp);
                        },
                  child: Text(
                    _signUp
                        ? 'Already have an account? Sign in'
                        : 'New to Naviigo? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
