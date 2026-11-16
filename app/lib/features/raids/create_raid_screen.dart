import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/boss_card.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/q_button.dart';
import '../hero/providers/profile_providers.dart';
import '../social/providers/guild_providers.dart';
import 'raid_widgets.dart';

const _types = [
  ('assignment', 'Assignment'),
  ('exam', 'Exam'),
  ('project', 'Project'),
];

/// Start a guild fight or party raid: who fights and the deadline, then the
/// AI-named boss to confirm.
class CreateRaidScreen extends ConsumerStatefulWidget {
  const CreateRaidScreen({super.key});

  @override
  ConsumerState<CreateRaidScreen> createState() => _CreateRaidScreenState();
}

class _CreateRaidScreenState extends ConsumerState<CreateRaidScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  var _source = 'party';
  var _type = 'assignment';
  var _participants = 4;
  DateTime? _deadline;
  var _busy = false;
  String? _error;
  Map<String, dynamic>? _preview;
  double _hours = 6;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _estimate() async {
    final title = _title.text.trim();
    if (title.isEmpty || title.length > 200) {
      setState(() => _error = 'Use a title of 1 to 200 characters.');
      return;
    }
    if (_deadline == null || !_deadline!.isAfter(DateTime.now())) {
      setState(() => _error = 'Pick a deadline in the future.');
      return;
    }
    final guildId = await ref.read(myGuildIdProvider.future);
    if (_source == 'guild' && guildId == null) {
      setState(() => _error = 'Join a guild before starting a guild fight.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final description = _description.text.trim();
      final json = await ref.read(apiClientProvider).createRaidPreview(
            source: _source,
            guildId: _source == 'guild' ? guildId : null,
            title: title,
            description: description.isEmpty ? null : description,
            type: _type,
            deadline: _deadline!,
            participants: _participants,
          );
      final preview = json['preview'];
      if (preview is! Map) {
        throw const ApiException(code: 'internal', message: 'Could not estimate this raid.');
      }
      final map = Map<String, dynamic>.from(preview);
      if (!mounted) return;
      setState(() {
        _preview = map;
        _hours = (map['perPersonHours'] as num?)?.toDouble() ?? 6;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not estimate this raid. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final preview = _preview;
    final deadline = _deadline;
    if (preview == null || deadline == null) return;
    final guildId = await ref.read(myGuildIdProvider.future);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final description = _description.text.trim();
      final json = await ref.read(apiClientProvider).createRaid(
            source: _source,
            guildId: _source == 'guild' ? guildId : null,
            title: _title.text.trim(),
            description: description.isEmpty ? null : description,
            type: _type,
            deadline: deadline,
            participants: _participants,
            perPersonHours: _hours.roundToDouble().clamp(2, 40),
            name: preview['name'] as String? ?? 'The Shared Deadline',
          );
      final raid = json['raid'];
      if (raid is! Map || raid['id'] is! String) {
        throw const ApiException(code: 'internal', message: 'Could not create this raid.');
      }
      if (!mounted) return;
      final id = raid['id'] as String;
      if (_source == 'party') {
        context.go('/raids/$id/invite');
      } else {
        context.go('/raids/$id');
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not create this raid. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _deadline == null ? const TimeOfDay(hour: 17, minute: 0) : TimeOfDay.fromDateTime(_deadline!),
    );
    if (time == null || !mounted) return;
    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _preview = null;
    });
  }

  void _setSource(String source) => setState(() {
        _source = source;
        _preview = null;
      });

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(raidRulesProvider).asData?.value;
    return Scaffold(
      appBar: _preview == null ? ClayHeader(title: 'Start a raid', onBack: () => context.go('/bosses')) : null,
      body: _preview == null ? _setup(context, rules) : _confirmView(context, _preview!, rules),
    );
  }

  Widget _setup(BuildContext context, RaidRules? rules) {
    final inGuild = ref.watch(myGuildIdProvider).asData?.value != null;
    final me = ref.watch(profileViewProvider).asData?.value.profile;
    final min = _source == 'guild' ? 2 : rules?.partyMin ?? 2;
    final max = _source == 'guild' ? rules?.guildMax ?? 10 : rules?.partyMax ?? 8;
    final deadline = _deadline;
    final days = deadline?.difference(DateTime.now()).inDays;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, raidDockClearance(context)),
          children: [
            const _Label('WHO FIGHTS'),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ModeCard(
                      title: 'Party',
                      body: 'Anyone with the code. ${rules?.partyMin ?? 2} to ${rules?.partyMax ?? 8} people, for one raid.',
                      icon: Icons.groups_rounded,
                      colors: const [AppColors.raidLight, AppColors.raidInk],
                      selected: _source == 'party',
                      onTap: _busy ? null : () => _setSource('party'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeCard(
                      title: 'Guild fight',
                      body: inGuild ? 'Your whole guild takes on the boss together.' : 'Join a guild to start a guild fight.',
                      icon: Icons.shield_rounded,
                      colors: const [AppColors.tealLight, AppColors.tealDeep],
                      selected: _source == 'guild',
                      enabled: inGuild,
                      onTap: !inGuild || _busy ? null : () => _setSource('guild'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Clay(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Label('THE SHARED DEADLINE'),
                  TextField(
                    controller: _title,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppText.h2.copyWith(fontSize: 19, height: 25 / 19),
                    decoration: InputDecoration(
                      hintText: 'HCI group presentation',
                      hintStyle: AppText.h2.copyWith(fontSize: 19, height: 25 / 19, color: AppColors.placeholder),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(top: 8, bottom: 4),
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  TextField(
                    controller: _description,
                    enabled: !_busy,
                    minLines: 1,
                    maxLines: 3,
                    style: AppText.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Add details for the estimate (optional)',
                      hintStyle: AppText.bodySmall.copyWith(color: AppColors.placeholder),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, thickness: 1, color: AppColors.hairline),
                  InkWell(
                    onTap: _busy ? null : _pickDeadline,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 46,
                      child: Row(
                        children: [
                          const Icon(Icons.event_rounded, size: 20, color: AppColors.tealDeep),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              deadline == null ? 'Pick the deadline' : raidDeadlineLabel(deadline),
                              style: AppText.title.copyWith(
                                fontSize: 14,
                                height: 18 / 14,
                                color: deadline == null ? AppColors.tealDeep : AppColors.ink,
                              ),
                            ),
                          ),
                          if (days != null)
                            Text(days <= 0 ? 'today' : days == 1 ? 'in 1 day' : 'in $days days', style: AppText.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.hairline),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final (i, entry) in _types.indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _Segment(
                            label: entry.$2,
                            selected: _type == entry.$1,
                            onTap: _busy ? null : () => setState(() => _type = entry.$1),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _Label(_source == 'guild' ? 'GUILD FIGHTERS' : 'PARTY SIZE'),
                const SizedBox(width: 8),
                Text('$min to $max', style: AppText.caption.copyWith(color: AppColors.inkFaint)),
              ],
            ),
            const SizedBox(height: 12),
            Clay(
              kind: ClayKind.control,
              radius: 26,
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Well(
                    circle: true,
                    width: 44,
                    height: 44,
                    onTap: _busy || _participants <= min
                        ? null
                        : () => setState(() {
                              _participants--;
                              _preview = null;
                            }),
                    child: Semantics(
                      button: true,
                      label: 'Fewer',
                      child: Icon(Icons.remove_rounded, color: _participants <= min ? AppColors.placeholder : AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < _participants.clamp(0, 6); i++)
                            Align(
                              widthFactor: i == 0 ? 1 : 0.8,
                              child: HeroHead(
                                size: 40,
                                skinId: i == 0 ? me?.equippedSkinId : 'skin_starter',
                                bodyType: i == 0 ? me?.bodyType : (i.isOdd ? 'b' : 'a'),
                              ),
                            ),
                          if (_participants > 6)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text('+${_participants - 6}', style: AppText.title.copyWith(fontSize: 14)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Clay(
                    kind: ClayKind.teal,
                    circle: true,
                    width: 44,
                    height: 44,
                    semanticLabel: 'More',
                    onTap: _busy || _participants >= max
                        ? null
                        : () => setState(() {
                              _participants++;
                              _preview = null;
                            }),
                    child: const Icon(Icons.add_rounded, color: AppColors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: AppText.title.copyWith(fontSize: 14, height: 18 / 14),
                children: [
                  TextSpan(text: '$_participants people'),
                  TextSpan(text: ' · HP grows with the party', style: AppText.bodySmall),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.tealDeep),
                const SizedBox(width: 6),
                Flexible(child: Text('The AI estimates the hours each person needs.', style: AppText.bodySmall)),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _ErrorText(_error!),
            ],
          ],
        ),
        RaidDock(
          child: QButton(
            label: 'Estimate the raid',
            icon: Icons.auto_awesome_rounded,
            height: 60,
            loading: _busy,
            onPressed: _busy ? null : _estimate,
          ),
        ),
      ],
    );
  }

  Widget _confirmView(BuildContext context, Map<String, dynamic> preview, RaidRules? rules) {
    final now = DateTime.now();
    final hours = _hours.roundToDouble().clamp(2.0, 40.0);
    final previewHours = (preview['perPersonHours'] as num?)?.toDouble() ?? hours;
    final tier = rules == null || hours == previewHours ? '${preview['tier'] ?? 'brute'}' : rules.tierFor(hours);
    final maxHp = (hours * 60).round() * _participants;
    final coins = rules?.baseLoot(tier) ?? (preview['defeatCoins'] as num?)?.round() ?? 0;
    final fairShare = rules?.fairShare(maxHp, _participants);
    final perPerson = (hours * 60).round();
    final eligible = preview['coinsEligible'] == true;
    final isGuild = _source == 'guild';
    final topInset = MediaQuery.paddingOf(context).top;
    final arenaHeight = 294 + topInset;
    final name = preview['name'] as String? ?? 'Raid';
    final bonus = ((rules?.victoryBonus ?? 0.25) * 100).round();
    final strong = AppText.bodySmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600);

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(bottom: raidDockClearance(context)),
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: arenaHeight,
                  child: const RaidArena(floor: Alignment(0, 0.78), floorWidth: 200),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: topInset + 4,
                  child: IgnorePointer(child: Center(child: BossArt(tier: tier, size: 262))),
                ),
                Positioned(
                  left: AppSpacing.screen,
                  right: AppSpacing.screen,
                  top: topInset + 12,
                  child: ArenaTopBar(
                    pill: isGuild ? 'GUILD FIGHT' : 'PARTY RAID',
                    onBack: _busy ? () {} : () => setState(() => _preview = null),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screen, arenaHeight - 24, AppSpacing.screen, 0),
                  child: Clay(
                    radius: 30,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.tealDeep),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'NAMED BY THE AI',
                                style: AppText.label.copyWith(fontSize: 11, height: 14 / 11, color: AppColors.tealDeep),
                              ),
                            ),
                            RaidTierTag(tier: tier, height: 22),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Semantics(
                          header: true,
                          child: Text(name, style: AppText.h1.copyWith(fontSize: 23, height: 29 / 23)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${preview['title'] ?? _title.text.trim()} · ${raidDueLabel(_deadline ?? now, now)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _HoursCell(
                              hours: hours.round(),
                              onLess: _busy || hours <= 2 ? null : () => setState(() => _hours = hours - 1),
                              onMore: _busy || hours >= 40 ? null : () => setState(() => _hours = hours + 1),
                            ),
                            const ValueDivider(),
                            ValueCell(value: '×$_participants', label: 'PEOPLE'),
                            const ValueDivider(),
                            ValueCell(value: formatCount(maxHp), label: 'HP', color: AppColors.bossHpText),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Clay(
                kind: ClayKind.control,
                radius: 24,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(GameAssets.icon('coin'), width: 32, height: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: eligible
                              ? Text.rich(TextSpan(style: AppText.bodySmall, children: [
                                  TextSpan(text: '${formatCount(coins)} coins each', style: strong),
                                  TextSpan(text: ', not split. Win before the deadline for +$bonus%.'),
                                ]))
                              : Text.rich(TextSpan(style: AppText.bodySmall, children: [
                                  TextSpan(text: 'No coins on this one.', style: strong),
                                  const TextSpan(text: ' It starts under 48 hours before the deadline.'),
                                ])),
                        ),
                      ],
                    ),
                    if (fairShare != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(color: AppColors.bossHpSoft, shape: BoxShape.circle),
                            child: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.bossHpText),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(TextSpan(style: AppText.bodySmall, children: [
                              TextSpan(text: 'Fair share: ${formatCount(fairShare)} damage.', style: strong),
                              TextSpan(
                                text: ' Deal at least that to get loot: '
                                    '${_fraction(rules!.fairShareRatio)} of ${formatCount(perPerson)} HP per person.',
                              ),
                            ])),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen + 8),
              child: Text(
                'Counts as 1 of your ${rules?.maxFights ?? 15} active fights. Members who join count it too.',
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: _ErrorText(_error!),
              ),
            ],
          ],
        ),
        RaidDock(
          child: QButton(
            label: isGuild ? 'Start the guild fight' : 'Start the raid',
            icon: isGuild ? Icons.shield_rounded : Icons.groups_rounded,
            height: 60,
            loading: _busy,
            onPressed: _busy ? null : _confirm,
          ),
        ),
      ],
    );
  }

  static String _fraction(double ratio) {
    if ((ratio - 0.5).abs() < 0.001) return 'half';
    return '${(ratio * 100).round()}%';
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.label.copyWith(fontSize: 12, height: 16 / 12, letterSpacing: 1));
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
    );
  }
}

/// Party or guild fight choice with an icon tile and a tick when picked.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.colors,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String body;
  final IconData icon;
  final List<Color> colors;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '$title. $body',
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Clay(
                radius: 28,
                onTap: onTap,
                border: selected ? Border.all(color: AppColors.teal, width: 2.5) : null,
              ),
            ),
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.16), offset: const Offset(3, 4), blurRadius: 8)],
                      ),
                      child: Icon(icon, color: AppColors.white, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(title, style: AppText.title.copyWith(fontSize: 16, height: 20 / 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(body, style: AppText.caption.copyWith(fontSize: 12, height: 16 / 12)),
                  ],
                ),
              ),
            ),
            if (selected)
              Positioned(
                right: -5,
                top: -7,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.tealDeep,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 3),
                  ),
                  child: const Icon(Icons.check_rounded, size: 14, color: AppColors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.caption.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.white : AppColors.inkMuted,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: selected
          ? Clay(kind: ClayKind.teal, radius: 17, height: 34, onTap: onTap, child: Center(child: text))
          : Well(radius: 17, height: 34, onTap: onTap, child: Center(child: text)),
    );
  }
}

/// Hours each, with small steppers so the estimate can be adjusted.
class _HoursCell extends StatelessWidget {
  const _HoursCell({required this.hours, required this.onLess, required this.onMore});

  final int hours;
  final VoidCallback? onLess;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String label, VoidCallback? onTap) => Semantics(
          button: true,
          label: label,
          child: Well(
            circle: true,
            width: 26,
            height: 26,
            onTap: onTap,
            child: Icon(icon, size: 15, color: onTap == null ? AppColors.placeholder : AppColors.ink),
          ),
        );
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              step(Icons.remove_rounded, 'Fewer hours', onLess),
              const SizedBox(width: 6),
              Text.rich(TextSpan(
                style: AppText.h2.copyWith(fontSize: 20, height: 24 / 20),
                children: [
                  TextSpan(text: '$hours'),
                  TextSpan(text: 'h', style: AppText.bodySmall.copyWith(fontSize: 13)),
                ],
              )),
              const SizedBox(width: 6),
              step(Icons.add_rounded, 'More hours', onMore),
            ],
          ),
          const SizedBox(height: 4),
          Text('EACH', style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1)),
        ],
      ),
    );
  }
}
