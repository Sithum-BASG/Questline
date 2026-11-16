import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/quest_seal.dart';
import '../bosses/providers/boss_providers.dart';
import '../onboarding/onboarding_skip_button.dart';
import 'providers/task_providers.dart';
import 'package:questline/core/assets/decode_size.dart';

final _onTimeBonusProvider = FutureProvider.autoDispose<double>(
  (ref) async => (await ref.read(gameConfigReaderProvider).xpRates()).onTimeBonus,
);

/// A fight a quest can join: a solo boss or a raid.
class _Fight {
  const _Fight({required this.id, required this.raid, required this.name, required this.tier, required this.deadline, required this.kind});

  final String id;
  final bool raid;
  final String name;
  final String tier;
  final DateTime deadline;

  /// "Warlord", "Raid" or "Guild fight".
  final String kind;
}

String _timeLeft(DateTime deadline) {
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) return 'Due';
  if (diff.inDays >= 1) return '${diff.inDays}d ${diff.inHours % 24}h left';
  if (diff.inHours >= 1) return '${diff.inHours}h left';
  return '${diff.inMinutes}m left';
}

String _capitalise(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

/// Title, optional notes, due date and boss fight. Judge inserts a draft row.
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key, this.onboarding = false, this.bossId, this.raidId});

  /// Onboarding saves the draft and lets the first-task screen show the judgement.
  final bool onboarding;

  /// When set, the draft is created under this boss.
  final String? bossId;

  /// Party raid or guild battle this task fights.
  final String? raidId;

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _due;
  late String? _bossId = widget.bossId;
  late String? _raidId = widget.raidId;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _judge() async {
    final title = _title.text.trim();
    if (title.isEmpty || title.length > 200) {
      setState(() => _error = 'Use a title of 1 to 200 characters.');
      return;
    }
    final notes = _notes.text.trim();
    if (notes.length > 1000) {
      setState(() => _error = 'Keep the notes to 1000 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref.read(insertDraftProvider)(
        title: title,
        notes: notes.isEmpty ? null : notes,
        dueAt: _due,
        bossId: _bossId,
        raidId: _raidId,
      );
      ref.invalidate(tasksProvider);
      if (!mounted) return;
      if (widget.onboarding) return;
      context.go('/quests/$id');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not save the draft. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _sameDay(DateTime? a, DateTime b) => a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _due ?? DateTime.now(),
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _toggleFight(_Fight fight) {
    setState(() {
      final selected = fight.raid ? _raidId == fight.id : _bossId == fight.id;
      _bossId = !selected && !fight.raid ? fight.id : null;
      _raidId = !selected && fight.raid ? fight.id : null;
    });
  }

  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final due = _due?.toLocal();
    final today = _today;
    final tomorrow = today.add(const Duration(days: 1));
    final isToday = _sameDay(due, today);
    final isTomorrow = _sameDay(due, tomorrow);
    final isCustom = due != null && !isToday && !isTomorrow;
    final canClose = !widget.onboarding && Navigator.of(context).canPop();
    final onTime = ref.watch(_onTimeBonusProvider).asData?.value ?? XpRates.defaults.onTimeBonus;
    final bosses = ref.watch(bossesProvider).asData?.value ?? const [];
    final raids = ref.watch(myRaidsProvider).asData?.value ?? const [];
    final fights = <_Fight>[
      for (final b in bosses)
        if (b.status == 'active' || b.status == 'staggered')
          _Fight(id: b.id, raid: false, name: b.name, tier: b.tier, deadline: b.deadline, kind: _capitalise(b.tier)),
      for (final r in raids)
        if (r.isActive)
          _Fight(
            id: r.raid.id,
            raid: true,
            name: r.raid.name,
            tier: r.raid.tier,
            deadline: r.raid.deadline,
            kind: r.isGuild ? 'Guild fight' : 'Raid',
          ),
    ];
    _Fight? linked;
    for (final f in fights) {
      if ((f.raid && f.id == _raidId) || (!f.raid && f.id == _bossId)) linked = f;
    }
    final insets = MediaQuery.paddingOf(context);
    final canJudge = _title.text.trim().isNotEmpty && !_busy;

    return Scaffold(
      backgroundColor: Color.alphaBlend(AppColors.scrim, AppColors.paper),
      body: Padding(
        padding: EdgeInsets.only(top: insets.top + 49),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.16), offset: const Offset(0, -12), blurRadius: 32)],
          ),
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            namesRoute: true,
            label: 'New quest',
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 10, 0, AppSpacing.s16),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(color: AppColors.handle, borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.screen),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text('New quest', style: AppText.h1.copyWith(fontSize: 22, height: 28 / 22)),
                              ),
                            ),
                            if (widget.onboarding) const OnboardingSkipButton(),
                            if (canClose)
                              ClayIconButton(
                                icon: Icons.close_rounded,
                                size: 40,
                                iconSize: 18,
                                tooltip: 'Close',
                                onPressed: () => Navigator.of(context).maybePop(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.screen),
                        child: _NoticeCard(title: _title, notes: _notes),
                      ),
                      const SizedBox(height: 26),
                      _Label(title: 'DUE', note: 'optional, on time earns +${(onTime * 100).round()}% XP'),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.only(right: AppSpacing.screen, bottom: 6),
                        child: Row(
                          children: [
                            _DueChip(label: 'None', selected: due == null, onTap: () => setState(() => _due = null)),
                            _DueChip(label: 'Today', selected: isToday, onTap: () => setState(() => _due = today)),
                            _DueChip(label: 'Tomorrow', selected: isTomorrow, onTap: () => setState(() => _due = tomorrow)),
                            _DueChip(
                              label: isCustom ? '${_wd[due.weekday - 1]} ${due.day} ${_mo[due.month - 1]}' : 'Pick a date',
                              icon: Icons.calendar_today_rounded,
                              selected: isCustom,
                              onTap: _pickDate,
                            ),
                          ],
                        ),
                      ),
                      if (fights.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const _Label(title: 'PART OF A BOSS FIGHT', note: 'optional'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.fromLTRB(0, 30, AppSpacing.screen, 14),
                          child: Row(
                            children: [
                              for (final fight in fights) ...[
                                _FightCard(
                                  fight: fight,
                                  selected: identical(fight, linked),
                                  onTap: () => _toggleFight(fight),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.screen),
                          child: Row(
                            children: [
                              const Icon(Icons.gavel_rounded, size: 15, color: AppColors.inkMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  linked == null
                                      ? 'Link it and every focus minute hits the boss.'
                                      : 'Focus minutes on this quest deal damage to ${linked.name}.',
                                  style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.screen),
                        child: Well(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                                child: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.tealDeep),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: AppText.bodySmall,
                                    children: [
                                      const TextSpan(text: 'The Judge sets the '),
                                      TextSpan(
                                        text: 'stat, difficulty and time',
                                        style: AppText.bodySmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                                      ),
                                      const TextSpan(text: '. You can change the stat after.'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.s16),
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.screen),
                          child: Text(
                            _error!,
                            style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, insets.bottom + 16),
                  child: Opacity(
                    opacity: canJudge || _busy ? 1 : 0.45,
                    child: QButton(
                      label: 'Judge quest',
                      icon: Icons.auto_awesome_rounded,
                      loading: _busy,
                      onPressed: canJudge ? _judge : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.screen),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: title),
            if (note != null)
              TextSpan(
                text: '  · $note',
                style: AppText.caption.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0, color: AppColors.inkFaint),
              ),
          ],
        ),
        style: AppText.label,
      ),
    );
  }
}

/// The blank notice: an unjudged seal waits for the Judge to stamp a stat on it.
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.title, required this.notes});

  final TextEditingController title;
  final TextEditingController notes;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(16, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const QuestSeal(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 2),
                    Text('QUEST', style: AppText.label),
                    const SizedBox(height: 4),
                    TextField(
                      controller: title,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      style: AppText.h2.copyWith(fontSize: 19, height: 25 / 19, fontWeight: FontWeight.w600),
                      decoration: InputDecoration.collapsed(
                        hintText: "What's the quest?",
                        hintStyle: AppText.h2.copyWith(
                          fontSize: 19,
                          height: 25 / 19,
                          fontWeight: FontWeight.w600,
                          color: AppColors.placeholder,
                        ),
                      ).copyWith(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 66),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1, thickness: 1, color: AppColors.hairline),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.notes_rounded, size: 16, color: AppColors.inkFaint),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: notes,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        style: AppText.body.copyWith(fontSize: 14, height: 20 / 14),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Add notes (optional)',
                          hintStyle: AppText.body.copyWith(fontSize: 14, height: 20 / 14, color: AppColors.placeholder),
                        ).copyWith(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FightCard extends StatelessWidget {
  const _FightCard({required this.fight, required this.selected, required this.onTap});

  final _Fight fight;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tier = GameAssets.bossTiers.contains(fight.tier) ? fight.tier : 'brute';
    final sky = fight.raid
        ? const [Color(0xFF8EA2FF), Color(0xFF3B3F96), Color(0xFF1B1D4F)]
        : const [Color(0xFFF59BB4), Color(0xFF6B2A6E), Color(0xFF2A2D74)];
    return Semantics(
      button: true,
      selected: selected,
      label: '${fight.name}, ${fight.kind}, ${_timeLeft(fight.deadline)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 150,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: selected ? [const BoxShadow(color: AppColors.tealDeep, spreadRadius: 3)] : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: Clay(radius: 24)),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 56,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(center: const Alignment(0, 1), radius: 1.2, colors: sky, stops: const [0, 0.55, 1]),
                    ),
                  ),
                ),
              ),
              Positioned(left: 41, top: -18, child: Image.asset(GameAssets.boss(tier), width: 68, height: 68, cacheWidth: decodeWidth(context, 68))),
              Positioned(
                left: 12,
                right: 10,
                top: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fight.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(fontSize: 13, height: 17 / 13),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${fight.kind} · ${_timeLeft(fight.deadline)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  right: -6,
                  top: -8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.tealDeep,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
                    ),
                    child: const Icon(Icons.check_rounded, size: 13, color: AppColors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Due $label',
        excludeSemantics: true,
        child: Clay(
          kind: selected ? ClayKind.teal : ClayKind.control,
          radius: 22,
          height: 44,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: selected ? AppColors.white : AppColors.ink),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppText.title.copyWith(fontSize: 14, color: selected ? AppColors.white : AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
