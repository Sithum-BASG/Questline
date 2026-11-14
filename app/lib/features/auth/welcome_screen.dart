import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/auth_providers.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import 'auth_errors.dart';
import 'password_strength.dart';
import 'widgets/auth_arch.dart';
import 'widgets/auth_error_pill.dart';
import 'widgets/auth_inset_field.dart';
import 'widgets/auth_or_divider.dart';
import 'widgets/auth_teal_button.dart';
import 'widgets/password_strength_meter.dart';

enum _AuthMode { signIn, signUp }

/// Email sign-up and sign-in. Mode toggle keeps the `/welcome` route.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _mode = _AuthMode.signIn;
  var _busy = false;
  var _googleBusy = false;
  var _obscure = true;
  AuthUiError? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < kMinPasswordLength) {
      setState(() {
        _error = AuthUiError(
          message: email.isEmpty
              ? 'Enter your email and a password of at least $kMinPasswordLength characters.'
              : 'Use a password of at least $kMinPasswordLength characters.',
          outline: email.isEmpty ? AuthFieldOutline.email : AuthFieldOutline.password,
        );
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_mode == _AuthMode.signUp) {
        await auth.signUp(email: email, password: password);
      } else {
        await auth.signIn(email: email, password: password);
      }
      await ref.read(completeOnboardingProvider)(
        'signed_in',
        data: const {'timezone': 'Asia/Colombo'},
      );
      ref.invalidate(onboardingStepProvider);
    } catch (error) {
      if (mounted) setState(() => _error = mapAuthFailure(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _googleBusy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle(serverClientId: googleWebClientId);
      await ref.read(completeOnboardingProvider)(
        'signed_in',
        data: const {'timezone': 'Asia/Colombo'},
      );
      ref.invalidate(onboardingStepProvider);
    } catch (error) {
      if (mounted) setState(() => _error = mapAuthFailure(error));
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = const AuthUiError(
          message: 'Enter your email to reset your password.',
          outline: AuthFieldOutline.email,
        );
      });
      return;
    }
    setState(() => _error = null);
    try {
      await ref.read(authRepositoryProvider).resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your email for a reset link')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = mapAuthFailure(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final signIn = _mode == _AuthMode.signIn;
    final anyBusy = _busy || _googleBusy;

    return Scaffold(
      backgroundColor: AppColors.authPage,
      // AuthArch measures from the screen top and handles the status bar itself.
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthArch(),
              const SizedBox(height: 24),
              Text(
                signIn ? 'Welcome back' : 'Begin your quest',
                style: AppText.authTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_error != null)
                Center(
                  child: AuthErrorPill(
                    message: _error!.message,
                    onSignInTap: _error!.signInAction
                        ? () => setState(() {
                              _mode = _AuthMode.signIn;
                              _error = null;
                            })
                        : null,
                  ),
                )
              else
                Text(
                  signIn
                      ? 'Your quests and bosses are waiting.'
                      : 'Make an account, then create your hero.',
                  style: AppText.authSubtitle,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              AuthInsetField(
                label: 'Email',
                controller: _email,
                icon: Icons.mail_outline,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                hasError: _error?.outline == AuthFieldOutline.email,
                onChanged: (_) => _clearError(),
              ),
              const SizedBox(height: 14),
              AuthInsetField(
                label: 'Password',
                controller: _password,
                icon: Icons.lock_outline,
                hint: 'Your password',
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: signIn
                    ? const [AutofillHints.password]
                    : const [AutofillHints.newPassword],
                hasError: _error?.outline == AuthFieldOutline.password,
                onChanged: (_) => setState(() => _error = null),
                trailing: AuthPasswordToggle(
                  visible: !_obscure,
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (signIn)
                _ForgotPasswordRow(onTap: anyBusy ? null : _forgotPassword)
              else ...[
                const SizedBox(height: 14),
                PasswordStrengthMeter(password: _password.text),
                const SizedBox(height: 22),
              ],
              AuthTealButton(
                label: signIn ? 'Sign in' : 'Create account',
                loadingLabel: signIn ? 'Signing in' : 'Creating account',
                loading: _busy,
                onPressed: anyBusy ? null : _submit,
              ),
              const SizedBox(height: 22),
              const AuthOrDivider(),
              const SizedBox(height: 6),
              AuthGoogleButton(
                loading: _googleBusy,
                onPressed: anyBusy ? null : _google,
              ),
              const SizedBox(height: 26),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: AppText.authFooter,
                    children: [
                      TextSpan(
                        text: signIn ? 'New here? ' : 'Already have an account? ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: anyBusy
                              ? null
                              : () => setState(() {
                                    _mode = signIn ? _AuthMode.signUp : _AuthMode.signIn;
                                    _error = null;
                                  }),
                          child: Text(
                            signIn ? 'Create an account' : 'Sign in',
                            style: AppText.authFooterAction,
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Right-aligned "Forgot password?" link. The row fills the whole 14 + 18 + 22
/// gap between the password field and the button so the tap target stays
/// ≥48 dp while the text sits 14 px below the field.
class _ForgotPasswordRow extends StatelessWidget {
  const _ForgotPasswordRow({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Align(
        alignment: Alignment.centerRight,
        child: Semantics(
          button: true,
          enabled: onTap != null,
          label: 'Forgot password?',
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.s8),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(8, 14, 4, 22),
              child: Text('Forgot password?', style: AppText.authLink),
            ),
          ),
        ),
      ),
    );
  }
}
