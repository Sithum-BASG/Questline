import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/supabase/auth_providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';

/// Writes the owner's study context. The column grant allows this client update.
final saveStudyContextProvider = Provider<Future<void> Function(String value)>((ref) {
  return (value) async {
    final userId = ref.read(authStateProvider).asData?.value.session?.user.id;
    if (userId == null) {
      throw const ApiException(code: 'unauthenticated', message: 'Sign in to continue.');
    }
    await ref.read(supabaseClientProvider)
        .from('user_settings')
        .update({'study_context': value})
        .eq('user_id', userId);
  };
});

/// Optional study context, then the study onboarding step.
class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  final _context = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _context.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool save}) async {
    final text = _context.text.trim();
    if (save && text.length > 80) {
      setState(() => _error = 'Keep it to 80 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (save && text.isNotEmpty) {
        await ref.read(saveStudyContextProvider)(text);
      }
      await ref.read(completeOnboardingProvider)('study');
      ref.invalidate(onboardingStepProvider);
      if (mounted) context.go('/onboarding/first-task');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
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
            Text('What are you studying?', style: AppText.h1),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Optional. For example, BSc IT, 3rd year.',
              style: AppText.body.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _context,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Study context'),
              style: AppText.body,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Task text and your optional study context are sent to our AI provider (Groq) to rate the task. Nothing else is shared.',
              style: AppText.bodySmall.copyWith(color: AppColors.inkMuted),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.s20),
            QButton(
              label: 'Continue',
              loading: _busy,
              onPressed: _busy ? null : () => _finish(save: true),
            ),
            const SizedBox(height: AppSpacing.s8),
            QButton(
              label: 'Skip',
              variant: QButtonVariant.text,
              onPressed: _busy ? null : () => _finish(save: false),
            ),
          ],
        ),
      ),
    );
  }
}
