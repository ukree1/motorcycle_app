import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/auth_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final AuthService authService = AuthService();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (loading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autoValidate = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => loading = true);

    try {
      await authService.register(
        email: emailController.text.trim(),
        // Passwords are never trimmed, so what the user typed is what is saved.
        password: passwordController.text,
      );

      // Force logout after register so the user signs in explicitly.
      await authService.logout();

      TextInput.finishAutofillContext();

      if (!mounted) return;

      showAuthSnack(context, 'Account created! Please sign in.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showAuthSnack(context, friendlyAuthError(e), error: true);
    } finally {
      // Guarded: the screen may already be popped (the old code could
      // call setState after dispose).
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _visibilityToggle({
    required bool obscured,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      onPressed: onPressed,
      icon: Icon(
        obscured
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        color: AuthColors.silver,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthCard(
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed:
                          loading ? null : () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to sign in'),
                      style: TextButton.styleFrom(
                        foregroundColor: AuthColors.silver,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Create your account',
                      style: TextStyle(
                        color: AuthColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start tracking your motorcycles and payments in minutes.',
                      style: TextStyle(
                        color: AuthColors.silverDim,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AuthField(
                      label: 'Email address',
                      hint: 'you@example.com',
                      icon: Icons.mail_outline_rounded,
                      controller: emailController,
                      enabled: !loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: AuthValidators.email,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 20),
                    AuthField(
                      label: 'Password',
                      hint: 'At least 8 characters',
                      icon: Icons.lock_outline_rounded,
                      controller: passwordController,
                      focusNode: _passwordFocus,
                      enabled: !loading,
                      obscure: obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: AuthValidators.newPassword,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _confirmFocus.requestFocus(),
                      suffix: _visibilityToggle(
                        obscured: obscurePassword,
                        onPressed: () => setState(
                          () => obscurePassword = !obscurePassword,
                        ),
                      ),
                    ),
                    PasswordStrength(password: passwordController.text),
                    const SizedBox(height: 20),
                    AuthField(
                      label: 'Confirm password',
                      hint: 'Re-enter your password',
                      icon: Icons.lock_reset_rounded,
                      controller: confirmController,
                      focusNode: _confirmFocus,
                      enabled: !loading,
                      obscure: obscureConfirm,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirm your password.';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                      onSubmitted: (_) => register(),
                      suffix: _visibilityToggle(
                        obscured: obscureConfirm,
                        onPressed: () => setState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AuthPrimaryButton(
                      label: 'Create Account',
                      icon: Icons.arrow_forward_rounded,
                      loading: loading,
                      onPressed: register,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'You will be asked to sign in after your account is created.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AuthColors.silverDim, fontSize: 11),
          ),
        ],
      ),
    );
  }
}