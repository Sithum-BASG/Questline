import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_chip.dart';
import '../../core/widgets/stage_card.dart';
import '../../core/widgets/clay.dart';

/// Body type and display name, with the starter skin on the stage.
class CharacterScreen extends ConsumerStatefulWidget {
  const CharacterScreen({super.key});

  @override
  ConsumerState<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends ConsumerState<CharacterScreen> {
  final _name = TextEditingController();
  var _body = BodyType.a;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 24) {
      setState(() => _error = 'Use a name of 1 to 24 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(completeOnboardingProvider)(
        'character',
        data: {'bodyType': _body.name, 'displayName': name},
      );
      ref.invalidate(onboardingStepProvider);
      if (mounted) context.go('/onboarding/story');
    } on ApiException catch (error) {
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s24, AppSpacing.screen, AppSpacing.s32),
          children: [
            Text('Who is waking up?', style: AppText.h1),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Pick a look and a name. You can change the outfit later.',
              style: AppText.body.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s32),
            // Clay frame drawn behind the stage so the hero can still break
            // out of the top (Clay clips its own child).
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(child: Clay(radius: AppRadius.hero)),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: StageCard(skinId: 'starter', backgroundId: 'starter', body: _body, width: 220),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QChip(
                  label: 'Look A',
                  selected: _body == BodyType.a,
                  onTap: () => setState(() => _body = BodyType.a),
                ),
                const SizedBox(width: AppSpacing.s8),
                QChip(
                  label: 'Look B',
                  selected: _body == BodyType.b,
                  onTap: () => setState(() => _body = BodyType.b),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            Text('NAME', style: AppText.label),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              style: AppText.body,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText)),
            ],
          ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s16),
              child: QButton(
                label: 'Continue',
                loading: _busy,
                onPressed: _busy ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
