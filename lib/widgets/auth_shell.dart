import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Black / silver / white palette used by the login and register screens.
class AuthColors {
  static const Color black = Color(0xFF050505);
  static const Color surface = Color(0xFF0E0E10);
  static const Color surfaceAlt = Color(0xFF151518);
  static const Color line = Color(0xFF2A2A30);
  static const Color silver = Color(0xFFC4C7CE);
  static const Color silverDim = Color(0xFF8A8D96);
  static const Color hint = Color(0xFF6B6E77);
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFFF6B6B);
}

/// Turns raw auth exceptions into messages a person can act on.
String friendlyAuthError(Object error) {
  final raw = error.toString();
  final text = raw.toLowerCase();

  if (text.contains('invalid-credential') ||
      text.contains('wrong-password') ||
      text.contains('user-not-found') ||
      text.contains('invalid login')) {
    return 'Incorrect email or password.';
  }
  if (text.contains('email-already-in-use')) {
    return 'An account with this email already exists.';
  }
  if (text.contains('weak-password')) {
    return 'Password is too weak. Try a longer one.';
  }
  if (text.contains('invalid-email')) {
    return 'Please enter a valid email address.';
  }
  if (text.contains('network-request-failed')) {
    return 'Network error. Check your connection and try again.';
  }
  if (text.contains('too-many-requests')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (text.contains('user-disabled')) {
    return 'This account has been disabled.';
  }
  return raw.replaceFirst('Exception: ', '');
}

/// Floating snackbar that stays a sensible width on desktop browsers.
void showAuthSnack(BuildContext context, String message,
    {bool error = false}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final width = math.min(420.0, screenWidth - 32);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: width > 0 ? width : null,
        backgroundColor:
            error ? const Color(0xFF2A1215) : const Color(0xFF1B1B1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: error ? const Color(0x66FF6B6B) : AuthColors.line,
          ),
        ),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline,
              color: error ? AuthColors.error : AuthColors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AuthColors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
}

class AuthValidators {
  static String? email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password.';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Create a password.';
    if (value.length < 8) return 'Use at least 8 characters.';
    return null;
  }
}

/// Page frame. Wide screens (web / tablet / desktop) get a split layout with a
/// brand panel; narrow screens (phones) get a single centered column.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child});

  final Widget child;

  static const double wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    return Theme(
      data: base.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AuthColors.black,
        colorScheme: const ColorScheme.dark(
          primary: AuthColors.white,
          secondary: AuthColors.silver,
          surface: AuthColors.surface,
          error: AuthColors.error,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AuthColors.white,
          selectionColor: Color(0x55C4C7CE),
          selectionHandleColor: AuthColors.silver,
        ),
      ),
      child: Scaffold(
        backgroundColor: AuthColors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= wideBreakpoint;

            if (wide) {
              return Row(
                children: [
                  const Expanded(flex: 11, child: _BrandPanel()),
                  Expanded(flex: 9, child: _FormArea(child: child)),
                ],
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                const _MobileBackdrop(),
                _FormArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _MobileBrand(),
                      const SizedBox(height: 28),
                      child,
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FormArea extends StatelessWidget {
  const _FormArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const verticalPadding = 32.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(
                  0.0,
                  constraints.maxHeight - verticalPadding * 2,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MobileBackdrop extends StatelessWidget {
  const _MobileBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1.1),
          radius: 1.1,
          colors: [Color(0x26C4C7CE), AuthColors.black],
        ),
      ),
    );
  }
}

class _MobileBrand extends StatelessWidget {
  const _MobileBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AuthLogo(size: 64),
        SizedBox(height: 16),
        Text(
          'MOTOR TRACKER',
          style: TextStyle(
            color: AuthColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFF9EA2AB)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x33FFFFFF), blurRadius: 30),
        ],
      ),
      child: Icon(
        Icons.two_wheeler_rounded,
        color: AuthColors.black,
        size: size * 0.55,
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A1E), AuthColors.black],
            ),
          ),
        ),
        const CustomPaint(painter: _GridPainter()),
        const Positioned(top: -140, right: -140, child: _Glow(size: 460)),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(56),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              AuthLogo(size: 48),
                              SizedBox(width: 14),
                              Text(
                                'MOTOR TRACKER',
                                style: TextStyle(
                                  color: AuthColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Text(
                            'Your ride.\nYour records.\nAlways on track.',
                            style: TextStyle(
                              color: AuthColors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Track installments, plan maintenance, and keep every motorcycle record in one place.',
                            style: TextStyle(
                              color: AuthColors.silver,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                          SizedBox(height: 36),
                          _Feature(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Installment tracking',
                            subtitle:
                                'See what you have paid and what is left, per motorcycle.',
                          ),
                          _Feature(
                            icon: Icons.build_outlined,
                            title: 'Maintenance checklist',
                            subtitle:
                                'Stay ahead of oil changes, tires, brakes, and more.',
                          ),
                          _Feature(
                            icon: Icons.devices_rounded,
                            title: 'Web and mobile',
                            subtitle:
                                'One account, the same records on any device.',
                          ),
                          Spacer(),
                          Text(
                            'MOTOR TRACKER • KEEP YOUR RIDE ROAD-READY',
                            style: TextStyle(
                              color: AuthColors.hint,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AuthColors.line),
            ),
            child: Icon(icon, color: AuthColors.silver, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AuthColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AuthColors.silverDim,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x22FFFFFF), Color(0x00FFFFFF)],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1;

    const step = 44.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

/// Card that holds the form.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AuthColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AuthColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Labeled text field with consistent styling, validation and autofill.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.suffix,
    this.enabled = true,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final Widget? suffix;
  final bool enabled;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AuthColors.silver,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscure,
          enableSuggestions: !obscure,
          autocorrect: false,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          cursorColor: AuthColors.white,
          style: const TextStyle(color: AuthColors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AuthColors.hint, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: AuthColors.silver),
            suffixIcon: suffix,
            filled: true,
            fillColor: AuthColors.surfaceAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: _border(AuthColors.line),
            enabledBorder: _border(AuthColors.line),
            disabledBorder: _border(AuthColors.line),
            focusedBorder: _border(AuthColors.white, 1.4),
            errorBorder: _border(AuthColors.error),
            focusedErrorBorder: _border(AuthColors.error, 1.4),
            errorStyle: const TextStyle(
              color: AuthColors.error,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthColors.white,
          foregroundColor: AuthColors.black,
          disabledBackgroundColor: const Color(0xFFB9BBC1),
          disabledForegroundColor: AuthColors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AuthColors.black,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 10),
                    Icon(icon, size: 19),
                  ],
                ],
              ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AuthColors.white,
          side: const BorderSide(color: Color(0xFF3A3A42)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AuthColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              color: AuthColors.silverDim,
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AuthColors.line)),
      ],
    );
  }
}

/// Four-segment password strength meter.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.password});

  final String password;

  int get _score {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final score = _score;
    const labels = ['Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    const colors = [
      AuthColors.error,
      AuthColors.error,
      AuthColors.silverDim,
      AuthColors.silver,
      AuthColors.white,
    ];
    final active = colors[score];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < 4; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: i < score ? active : AuthColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              labels[score],
              textAlign: TextAlign.right,
              style: TextStyle(
                color: active,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}