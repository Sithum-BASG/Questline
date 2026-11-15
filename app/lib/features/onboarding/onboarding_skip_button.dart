import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/supabase/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/q_button.dart';

/// "Skip for now" on the optional onboarding steps (first quest, first focus).
/// Finishes onboarding without the starter bonuses for the skipped steps.
class OnboardingSkipButton extends ConsumerStatefulWidget {
  const OnboardingSkipButton({super.key, this.foreground = AppColors.inkMuted});

  final Color foreground;

  @override
  ConsumerState<OnboardingSkipButton> createState() => _OnboardingSkipButtonState();
}

class _OnboardingSkipButtonState extends ConsumerState<OnboardingSkipButton> {
  var _busy = false;

  Future<void> _skip() async {
    setState(() => _busy = true);
    try {
      await ref.read(completeOnboardingProvider)('done');
      ref.invalidate(onboardingStepProvider);
      if (mounted) context.go('/home');
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Could not skip right now. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return QButton(
      label: 'Skip for now',
      variant: QButtonVariant.text,
      foreground: widget.foreground,
      loading: _busy,
      onPressed: _busy ? null : _skip,
    );
  }
}
