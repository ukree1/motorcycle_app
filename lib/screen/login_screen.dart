import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/auth_shell.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final AuthService authService = AuthService();

  bool loading = false;
  bool obscurePassword = true;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (loading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autoValidate = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => loading = true);

    try {
      await authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Lets browsers / password managers offer to save the credentials.
      TextInput.finishAutofillContext();

      // If your app root already switches screens on authStateChanges,
      // this screen is gone by now and we simply stop here.
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showAuthSnack(context, friendlyAuthError(e), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: AuthColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to manage your motorcycles and installments.',
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
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      validator: AuthValidators.email,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 20),
                    AuthField(
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outline_rounded,
                      controller: passwordController,
                      focusNode: _passwordFocus,
                      enabled: !loading,
                      obscure: obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: AuthValidators.requiredPassword,
                      onSubmitted: (_) => login(),
                      suffix: IconButton(
                        tooltip: obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () {
                          setState(() => obscurePassword = !obscurePassword);
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AuthColors.silver,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AuthPrimaryButton(
                      label: 'Sign In',
                      icon: Icons.arrow_forward_rounded,
                      loading: loading,
                      onPressed: login,
                    ),
                    const SizedBox(height: 26),
                    const AuthDivider(label: 'NEW TO MOTOR TRACKER?'),
                    const SizedBox(height: 20),
                    AuthSecondaryButton(
                      label: 'Create an account',
                      onPressed: loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 15,
                color: AuthColors.silverDim,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Secure access to your installment records',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AuthColors.silverDim, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}