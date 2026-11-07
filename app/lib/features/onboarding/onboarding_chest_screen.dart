import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/auth_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../chests/providers/chest_providers.dart';
import 'onboarding_flags.dart';

/// Onboarding step 6: open the free chest from the first-session bonus.
class OnboardingChestScreen extends ConsumerStatefulWidget {
  const OnboardingChestScreen({super.key});

  @override
  ConsumerState<OnboardingChestScreen> createState() => _OnboardingChestScreenState();
}

class _OnboardingChestScreenState extends ConsumerState<OnboardingChestScreen> {
  var _busy = false;
  String? _error;

  Future<void> _openFreeChest() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(apiClientProvider).openChest(
            requestId: 'onboarding-free-${DateTime.now().millisecondsSinceEpoch}',
            useFreeChest: true,
          );
      if (!mounted) return;
      ref.invalidate(chestScreenProvider);
      await context.push('/chests/open', extra: result);
      if (!mounted) return;
      await ref.read(completeOnboardingProvider)('done');
      ref.read(pendingOnboardingChestProvider.notifier).setPending(false);
      ref.invalidate(onboardingStepProvider);
      if (mounted) context.go('/home');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(GameAssets.icon('chest_large'), width: 160, height: 160),
              const SizedBox(height: AppSpacing.s24),
              Text('Your free chest is ready', style: AppText.h1, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Level 2 unlocked a frame — open the chest for your first loot.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(_error!, style: AppText.bodySmall, textAlign: TextAlign.center),
              ],
              const Spacer(),
              QButton(
                label: _busy ? 'Opening…' : 'Open free chest',
                onPressed: _busy ? null : _openFreeChest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
