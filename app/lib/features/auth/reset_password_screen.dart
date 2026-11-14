import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import 'auth_errors.dart';
import 'password_strength.dart';
import 'providers/password_recovery_provider.dart';
import 'widgets/auth_error_pill.dart';
import 'widgets/auth_inset_field.dart';
import 'widgets/auth_teal_button.dart';
import 'widgets/password_strength_meter.dart';

/// Set a new password after opening the email reset link.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _busy = false;
  var _obscure = true;
  var _obscureConfirm = true;
  AuthUiError? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _password.text;
    final confirm = _confirm.text;
    if (password.length < kMinPasswordLength) {
      setState(() {
        _error = AuthUiError(
          message: 'Use a password of at least $kMinPasswordLength characters.',
          outline: AuthFieldOutline.password,
        );
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _error = const AuthUiError(
          message: "Those passwords don't match.",
          outline: AuthFieldOutline.password,
        );
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(password);
      ref.read(passwordRecoveryProvider.notifier).clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. You are signed in.')),
      );
      context.go('/home');
    } catch (error) {
      if (mounted) setState(() => _error = mapAuthFailure(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            40,
            AppSpacing.screen,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose a new password',
                style: AppText.authTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_error != null)
                Center(child: AuthErrorPill(message: _error!.message))
              else
                const Text(
                  'Pick something memorable — at least 6 characters.',
                  style: AppText.authSubtitle,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              AuthInsetField(
                label: 'New password',
                controller: _password,
                icon: Icons.lock_outline,
                hint: 'At least 6 characters',
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                hasError: _error?.outline == AuthFieldOutline.password,
                onChanged: (_) => setState(() => _error = null),
                trailing: AuthPasswordToggle(
                  visible: !_obscure,
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 14),
              AuthInsetField(
                label: 'Confirm password',
                controller: _confirm,
                icon: Icons.lock_outline,
                hint: 'Type it again',
                obscureText: _obscureConfirm,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() => _error = null),
                trailing: AuthPasswordToggle(
                  visible: !_obscureConfirm,
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 14),
              PasswordStrengthMeter(password: _password.text),
              const SizedBox(height: 22),
              AuthTealButton(
                label: 'Update password',
                loadingLabel: 'Updating',
                loading: _busy,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
