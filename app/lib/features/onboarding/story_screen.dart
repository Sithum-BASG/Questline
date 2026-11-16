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
import '../../core/widgets/clay.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/loading_skeleton.dart';

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

  Duration get _turn => Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 150 : 280);

  void _advance() {
    if (_card >= 6) return;
    _pages.nextPage(duration: _turn, curve: Curves.easeOut);
  }

  void _back() {
    if (_card <= 0) return;
    _pages.previousPage(duration: _turn, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final look = ref.watch(onboardingLookProvider);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: look.when(
        loading: () => const LoadingSkeleton(),
        error: (_, _) => const Center(child: Text('Could not load your character.')),
        data: (value) {
          final body = value?.body ?? BodyType.a;
          final name = value?.displayName ?? '';
          final last = _card == 6;
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 9, AppSpacing.screen, 0),
                  child: _StoryProgress(card: _card),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: 7,
                    onPageChanged: (card) => setState(() => _card = card),
                    itemBuilder: (context, index) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _advance,
                      child: _StoryCard(index: index, body: body, name: name, onSkip: _busy ? null : _finish),
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 8),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppText.bodySmall.copyWith(color: AppColors.errorText),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 4, AppSpacing.screen, AppSpacing.s16),
                  child: last
                      ? QButton(
                          label: 'Begin',
                          icon: Icons.auto_awesome_rounded,
                          loading: _busy,
                          onPressed: _busy ? null : _finish,
                        )
                      : SizedBox(
                          height: 64,
                          child: Row(
                            children: [
                              Opacity(
                                opacity: _card == 0 ? 0.4 : 1,
                                child: ClayIconButton(
                                  icon: Icons.chevron_left_rounded,
                                  tooltip: 'Previous card',
                                  size: 56,
                                  onPressed: _card == 0 ? null : _back,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Tap or swipe',
                                  textAlign: TextAlign.center,
                                  style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: 'Next card',
                                excludeSemantics: true,
                                child: Clay(
                                  kind: ClayKind.teal,
                                  circle: true,
                                  width: 64,
                                  height: 64,
                                  onTap: _advance,
                                  child: const Icon(Icons.chevron_right_rounded, size: 30, color: AppColors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

const _kickers = ['ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN'];

class _StoryProgress extends StatelessWidget {
  const _StoryProgress({required this.card});

  final int card;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Card ${card + 1} of 7',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(color: AppColors.strengthEmpty, borderRadius: BorderRadius.circular(2)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: i < card ? 1 : (i == card ? 0.55 : 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.tealDeep, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.index, required this.body, required this.name, required this.onSkip});

  final int index;
  final BodyType body;
  final String name;

  /// Skip sits on the picture on every card but the last.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final last = index == 6;
    return Column(
      children: [
        const SizedBox(height: 18),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 438),
              child: Clay(
                radius: 34,
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: AppColors.sceneMid),
                      Image.asset(
                        GameAssets.story(index + 1, body),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        semanticLabel: _alts[index],
                      ),
                      if (!last)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Semantics(
                            button: true,
                            label: 'Skip',
                            excludeSemantics: true,
                            child: Clay(
                              kind: ClayKind.onScene,
                              radius: 17,
                              height: 34,
                              onTap: onSkip,
                              padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Skip', style: AppText.title.copyWith(fontSize: 13, height: 16 / 13)),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.ink),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 12),
          child: Column(
            children: [
              Text(
                _kickers[index],
                style: AppText.label.copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 1.5, color: AppColors.tealDeep),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 29 * 4,
                child: last
                    ? _LastCard(name: name)
                    : Text(storyCards[index], textAlign: TextAlign.center, style: _lineStyle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _alts = [
  'A student slumped over a planner at night',
  'Ink rising out of the planner with glowing eyes',
  'Ink monsters hiding around the campus',
  'A deadline golem grown huge in the dorm room',
  'The planner glowing teal as the student focuses',
  'The student striking an ink monster with light',
  'Friends looking out over a magical campus',
];

final _lineStyle = AppText.h2.copyWith(fontSize: 21, height: 29 / 21, fontWeight: FontWeight.w600, letterSpacing: -0.4);

class _LastCard extends StatelessWidget {
  const _LastCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: _lineStyle,
        children: [
          const TextSpan(text: 'You\'re not the only one who can see them. '),
          TextSpan(
            text: name.isEmpty ? 'Your first quest is waiting.' : '$name, your first quest is waiting.',
            style: _lineStyle.copyWith(color: AppColors.tealDeep),
          ),
        ],
      ),
    );
  }
}
