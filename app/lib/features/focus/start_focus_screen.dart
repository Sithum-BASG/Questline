import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/stat_icon.dart';
import '../../data/models/task.dart';
import '../quests/providers/task_providers.dart';
import 'focus_session_info.dart';

final startSessionProvider =
    Provider<Future<StartSessionResult> Function({required String taskId, required String mode, bool usePotion})>((
      ref,
    ) {
      return ({required String taskId, required String mode, bool usePotion = false}) {
        return ref.read(apiClientProvider).startSession(taskId: taskId, mode: mode, usePotion: usePotion);
      };
    });

final potionCountProvider = FutureProvider.autoDispose<int>((ref) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final row = await client.from('player_state').select('potions').maybeSingle();
  return (row?['potions'] as num?)?.toInt() ?? 0;
});

/// Names of your bosses and raids by id, for the quest rows.
final _targetNamesProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final bosses = await client.from('bosses').select('id, name');
  final raids = await client.from('raids').select('id, name');
  return {
    for (final row in [...bosses, ...raids])
      if (row['id'] is String && row['name'] is String) row['id'] as String: row['name'] as String,
  };
});

const _maxQuestRows = 3;

class StartFocusScreen extends ConsumerStatefulWidget {
  const StartFocusScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<StartFocusScreen> createState() => _StartFocusScreenState();
}

class _StartFocusScreenState extends ConsumerState<StartFocusScreen> {
  String? _picked;
  var _mode = 'focus';
  var _potion = false;
  var _busy = false;
  String? _error;

  void _pick(String id) {
    if (id == _picked) return;
    setState(() {
      _picked = id;
      _mode = 'focus';
      _potion = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    return Scaffold(
      appBar: const ClayHeader(title: 'Start focus', closeIcon: true),
      body: tasks.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load quests',
          body: 'Check your connection and try again.',
          icon: Icons.cloud_off_rounded,
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(tasksProvider),
        ),
        data: (rows) {
          final open = rows.where((task) => task.status == 'open').toList()
            ..sort((a, b) {
              final da = a.dueAt, db = b.dueAt;
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });
          final wanted = _picked ?? (widget.taskId.isEmpty ? null : widget.taskId);
          Task? selected;
          for (final task in open) {
            if (task.id == wanted) selected = task;
          }
          selected ??= wanted == null && open.isNotEmpty ? open.first : null;
          if (selected == null) {
            if (wanted != null) {
              return const EmptyState(
                title: 'Quest not found',
                body: 'It may have been finished or discarded.',
                icon: Icons.search_off_rounded,
              );
            }
            return EmptyState(
              title: 'No open quests',
              body: 'Add a quest before starting focus.',
              actionLabel: 'Add quest',
              onAction: () => context.go('/quests/new'),
            );
          }
          final shown = open.take(_maxQuestRows).toList();
          if (!shown.contains(selected)) {
            if (shown.length == _maxQuestRows) shown.removeLast();
            shown.add(selected);
          }
          return _Body(
            task: selected,
            quests: shown,
            mode: _mode,
            potion: _potion,
            busy: _busy,
            error: _error,
            onPick: _pick,
            onMode: (m) => setState(() {
              _mode = m;
              if (m == 'activity') _potion = false;
            }),
            onPotion: (v) => setState(() => _potion = v),
            onStart: _start,
          );
        },
      ),
    );
  }

  Future<void> _start(Task task) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final started = await ref.read(startSessionProvider)(taskId: task.id, mode: _mode, usePotion: _potion);
      if (!mounted) return;
      context.push(
        '/focus/${started.sessionId}',
        extra: {
          'startedAt': started.startedAt,
          'estimateMinutes': task.estMinutes ?? 0,
          'mode': _mode,
          'stat': task.stat ?? 'intellect',
        },
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.task,
    required this.quests,
    required this.mode,
    required this.potion,
    required this.busy,
    required this.error,
    required this.onPick,
    required this.onMode,
    required this.onPotion,
    required this.onStart,
  });

  final Task task;
  final List<Task> quests;
  final String mode;
  final bool potion;
  final bool busy;
  final String? error;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onMode;
  final ValueChanged<bool> onPotion;
  final void Function(Task task) onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(focusTaskInfoProvider(task.id)).asData?.value;
    final names = ref.watch(_targetNamesProvider).asData?.value ?? const {};
    final potions = ref.watch(potionCountProvider).asData?.value ?? 0;
    final rates = info?.rates ?? XpRates.defaults;
    final stat = task.stat ?? 'intellect';
    final statLabel = StatIcon.labelFor(stat);
    final canToggle = stat == 'vitality' || stat == 'charisma';
    final activity = canToggle && mode == 'activity';
    final estimate = task.estMinutes ?? 0;
    final potionUsable = !activity && estimate >= rates.potionMinMinutes;
    final capMinutes = ((activity ? rates.activityCapRatio : rates.focusCapRatio) * estimate).round();
    final xp = info?.previewXp(capMinutes.toDouble(), activity: activity, usePotion: potion && potionUsable);
    final linked = task.bossId != null || task.raidId != null;
    final raid = task.bossId == null && task.raidId != null;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.screen, 6, AppSpacing.screen, bottom + 130),
          children: [
            const _Label(title: 'QUEST', note: "today's open quests"),
            const SizedBox(height: 10),
            Semantics(
              container: true,
              label: 'Quest',
              child: Clay(
                radius: 26,
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    for (final quest in quests)
                      _QuestRow(
                        task: quest,
                        selected: quest.id == task.id,
                        target: names[quest.bossId ?? quest.raidId],
                        onTap: () => onPick(quest.id),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _Label(title: 'MODE', note: canToggle ? 'pick how you will do it' : null),
            const SizedBox(height: 10),
            if (canToggle)
              _ModeToggle(value: activity ? 'activity' : 'focus', onChanged: onMode)
            else
              Well(
                height: 48,
                radius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.tealDeep),
                    const SizedBox(width: 8),
                    Text('Focus', style: AppText.title.copyWith(fontSize: 14, color: AppColors.tealDeep)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '· the only mode for $statLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                activity
                    ? 'Phone can be locked · counts up to ~$capMinutes min · ${(rates.activityShare * 100).round()}% XP'
                    : 'Leaving Questline for ${rates.graceSeconds}+ seconds ends the session.',
                style: AppText.caption.copyWith(fontWeight: FontWeight.w400, height: 18 / 12),
              ),
            ),
            if (potions > 0) ...[
              const SizedBox(height: 18),
              _PotionRow(
                on: potion && potionUsable,
                usable: potionUsable,
                subtitle: potionUsable
                    ? '${_fmt(rates.potionMultiplier)}× XP this session · $potions held'
                    : activity
                    ? 'Focus mode only'
                    : 'Quests of ${rates.potionMinMinutes.round()}+ min only',
                onChanged: onPotion,
              ),
            ],
            const SizedBox(height: 18),
            Clay(
              radius: 26,
              height: 78,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _ValueCell(
                      value: xp == null ? '—' : '$xp',
                      unit: xp == null ? null : 'XP',
                      label: 'UP TO',
                      color: AppColors.tealDeep,
                    ),
                  ),
                  Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 16), color: AppColors.hairline),
                  Expanded(
                    child: _ValueCell(
                      value: activity || !linked ? '—' : '$capMinutes',
                      label: activity
                          ? 'NO DAMAGE IN ACTIVITY'
                          : !linked
                          ? 'NO BOSS LINKED'
                          : raid
                          ? 'RAID DAMAGE'
                          : 'BOSS DAMAGE',
                      color: activity || !linked ? AppColors.inkMuted : AppColors.bossHpText,
                    ),
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.s16),
              Text(
                error!,
                style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        DockedAction(
          bottom: bottom + 24,
          child: QButton(
            label: activity ? 'Start activity' : 'Start focus',
            icon: Icons.play_arrow_rounded,
            loading: busy,
            onPressed: busy ? null : () => onStart(task),
          ),
        ),
      ],
    );
  }
}

String _fmt(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

class _Label extends StatelessWidget {
  const _Label({required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
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
    );
  }
}

String _dueLabel(Task task) {
  final due = task.dueAt?.toLocal();
  if (due == null) return 'No due date';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(due.year, due.month, due.day);
  if (day.isBefore(today)) return 'Overdue';
  if (day == today) return 'Due today';
  final days = day.difference(today).inDays;
  return days == 1 ? 'Due tomorrow' : 'Due in ${days}d';
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.task, required this.selected, required this.target, required this.onTap});

  final Task task;
  final bool selected;
  final String? target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stat = task.stat ?? 'intellect';
    final estimate = task.estMinutes;
    final meta = [if (estimate != null && estimate > 0) '~$estimate min'];
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${task.title}, ${[...meta, target ?? _dueLabel(task)].join(', ')}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: 64,
            padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
            decoration: BoxDecoration(
              color: selected ? AppColors.tealSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? AppColors.tealDeep : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                ClayDot(size: 36, gradient: statGradient(stat), icon: StatIcon.iconFor(stat), iconSize: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title.copyWith(fontSize: 15, height: 20 / 15),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (meta.isNotEmpty)
                            Text('${meta.first} · ', style: AppText.caption.copyWith(fontWeight: FontWeight.w500)),
                          if (target != null) ...[
                            const Icon(Icons.flag_rounded, size: 11, color: AppColors.bossHpText),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              target ?? _dueLabel(task),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.tealDeep : Colors.transparent,
                    border: selected ? null : Border.all(color: AppColors.handle, width: 2),
                  ),
                  child: selected ? const Icon(Icons.check_rounded, size: 15, color: AppColors.white) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const modes = [('focus', 'Focus', Icons.timer_outlined), ('activity', 'Activity', Icons.directions_run_rounded)];
    final index = value == 'activity' ? 1 : 0;
    return Well(
      height: 48,
      radius: 24,
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: const Clay(kind: ClayKind.control, radius: 20),
              ),
              Row(
                children: [
                  for (final (id, label, icon) in modes)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: value == id,
                        label: label,
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => onChanged(id),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 16, color: value == id ? AppColors.tealDeep : AppColors.inkMuted),
                                const SizedBox(width: 7),
                                Text(
                                  label,
                                  style: AppText.title.copyWith(
                                    fontSize: 14,
                                    color: value == id ? AppColors.tealDeep : AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PotionRow extends StatelessWidget {
  const _PotionRow({required this.on, required this.usable, required this.subtitle, required this.onChanged});

  final bool on;
  final bool usable;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: on,
      enabled: usable,
      label: 'Use a Focus Potion. $subtitle',
      excludeSemantics: true,
      child: Opacity(
        opacity: usable ? 1 : 0.45,
        child: Clay(
          kind: ClayKind.control,
          radius: 24,
          height: 64,
          onTap: usable ? () => onChanged(!on) : null,
          padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                padding: const EdgeInsets.all(4),
                child: Image.asset(GameAssets.icon('focus_potion')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Focus Potion', style: AppText.title.copyWith(fontSize: 15, height: 20 / 15)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ClaySwitch(on: on),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClaySwitch extends StatelessWidget {
  const _ClaySwitch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 50,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: on ? clayTealGradient : null,
        color: on ? null : AppColors.strengthEmpty,
      ),
      child: CustomPaint(
        painter: InnerShadowPainter(
          borderRadius: BorderRadius.circular(15),
          shadows: on
              ? const [
                  InnerShadow(Offset(-2, -2), 4, Color(0x26000000)),
                  InnerShadow(Offset(2, 2), 4, Color(0x40FFFFFF)),
                ]
              : const [InnerShadow(Offset(2, 2), 4, Color(0x1F101935))],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.25), offset: const Offset(1, 2), blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.value, required this.label, required this.color, this.unit});

  final String value;
  final String? unit;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = AppText.numbers.copyWith(fontSize: 22, height: 26 / 22, letterSpacing: -0.4, color: color);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: value),
              if (unit != null) TextSpan(text: ' $unit', style: style.copyWith(fontSize: 12)),
            ],
          ),
          maxLines: 1,
          style: style,
        ),
        const SizedBox(height: 4),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FocusTileLabel(label)),
      ],
    );
  }
}
