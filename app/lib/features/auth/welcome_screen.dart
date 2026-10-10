import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/auth_providers.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';

/// Email sign-up and sign-in. One sentence, then the form.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool create}) async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      setState(() => _error = 'Use an email and a password of at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      if (create) {
        await auth.signUp(email: email, password: password);
      } else {
        await auth.signIn(email: email, password: password);
      }
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle(serverClientId: googleWebClientId);
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            const SizedBox(height: AppSpacing.s40),
            Text('Questline', style: AppText.h1),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Your deadlines were always monsters. Now you can fight back.',
              style: AppText.body.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s32),
            QCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                    style: AppText.body,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    style: AppText.body,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
                  ],
                  const SizedBox(height: AppSpacing.s20),
                  QButton(
                    label: 'Create account',
                    loading: _busy,
                    onPressed: _busy ? null : () => _submit(create: true),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  QButton(
                    label: 'Sign in',
                    variant: QButtonVariant.secondary,
                    loading: _busy,
                    onPressed: _busy ? null : () => _submit(create: false),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  QButton(
                    label: 'Continue with Google',
                    variant: QButtonVariant.text,
                    loading: _busy,
                    onPressed: _busy ? null : _google,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
