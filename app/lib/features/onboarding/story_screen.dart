import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/auth_providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';

/// Display name and body type chosen on the character screen.
class OnboardingLook {
  const OnboardingLook({required this.displayName, required this.body});

  final String displayName;
  final BodyType body;
}

/// The signed-in player's name and body type, used so the story resumes after a restart.
final onboardingLookProvider = FutureProvider<OnboardingLook?>((ref) async {
  final userId = ref.watch(authStateProvider).asData?.value.session?.user.id;
  if (userId == null) return null;
  final row = await ref.watch(supabaseClientProvider)
      .from('profiles')
      .select('display_name, body_type')
      .eq('id', userId)
      .maybeSingle();
  if (row == null) return null;
  final name = row['display_name'];
  return OnboardingLook(
    displayName: name is String ? name : '',
    body: row['body_type'] == 'b' ? BodyType.b : BodyType.a,
  );
});

const storyCards = <String>[
  'Lectures. Assignments. A planner that never stops filling up. Just another semester.',
  'Then one night, the ink in your planner moved.',
  'Your deadlines were always monsters. You just couldn\'t see them.',
  'Every day you leave them alone, they grow stronger.',
  'But the moment you truly focus, something in you wakes up.',
  'Every focused minute strikes them. Every task you finish makes you, and your world, more magical.',
];

/// Seven story cards. Skip or Begin stores the story step so a restart resumes at study.
class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({super.key, this.initialCard = 0});

  final int initialCard;

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen> {
  late final PageController _pages = PageController(initialPage: widget.initialCard);
  late int _card = widget.initialCard;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(completeOnboardingProvider)('story');
      ref.invalidate(onboardingStepProvider);
      if (mounted) context.go('/onboarding/study');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _advance() {
    if (_card >= 6) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    _pages.nextPage(
      duration: Duration(milliseconds: reduce ? 150 : 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final look = ref.watch(onboardingLookProvider);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: look.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load your character.')),
        data: (value) {
          final body = value?.body ?? BodyType.a;
          final name = value?.displayName ?? '';
          final last = _card == 6;
          return SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pages,
                  itemCount: 7,
                  onPageChanged: (card) => setState(() => _card = card),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: _advance,
                      child: Column(
                        children: [
                          Expanded(child: _StoryImage(card: index + 1, body: body)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screen,
                              AppSpacing.s8,
                              AppSpacing.screen,
                              AppSpacing.s20,
                            ),
                            child: index == 6
                                ? _LastCard(name: name)
                                : Text(storyCards[index], style: AppText.h2),
                          ),
                          const SizedBox(height: AppSpacing.minTap + AppSpacing.s16),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  right: AppSpacing.screen,
                  bottom: AppSpacing.s16,
                  child: QButton(
                    label: last ? 'Begin' : 'Skip',
                    variant: last ? QButtonVariant.primary : QButtonVariant.secondary,
                    loading: _busy,
                    onPressed: _busy ? null : _finish,
                  ),
                ),
                if (_error != null)
                  Positioned(
                    left: AppSpacing.screen,
                    right: AppSpacing.screen,
                    bottom: AppSpacing.minTap + AppSpacing.s24,
                    child: Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LastCard extends StatelessWidget {
  const _LastCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppText.h2,
        children: [
          const TextSpan(text: 'You\'re not the only one who can see them. '),
          TextSpan(
            text: '$name, your first quest is waiting.',
            style: AppText.h2.copyWith(color: AppColors.tealDeep),
          ),
        ],
      ),
    );
  }
}

class _StoryImage extends StatelessWidget {
  const _StoryImage({required this.card, required this.body});

  final int card;
  final BodyType body;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          stops: [0, GameAssets.storyFadeStart, 1],
        ).createShader(bounds);
      },
      child: Image.asset(
        GameAssets.story(card, body),
        fit: BoxFit.cover,
        width: double.infinity,
        alignment: Alignment.topCenter,
      ),
    );
  }
}
