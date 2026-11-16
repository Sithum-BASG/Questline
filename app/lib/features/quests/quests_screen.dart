import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/stat_icon.dart';
import '../../data/models/task.dart';
import 'providers/task_providers.dart';
import 'quest_filters.dart';
import '../../core/widgets/loading_skeleton.dart';

const _stats = ['intellect', 'vitality', 'craft', 'charisma'];

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Quest board: today / upcoming / done, a stat filter, and quest cards.
/// Adding a quest opens the draft sheet.
class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key, this.now});

  final DateTime? now;

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  var _bucket = QuestBucket.today;
  String? _stat;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final now = widget.now ?? DateTime.now();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            tasks.when(
              loading: () => Column(
                children: [
                  _Header(now: now),
                  const Expanded(child: LoadingSkeleton()),
                ],
              ),
              error: (error, _) => Column(
                children: [
                  _Header(now: now),
                  EmptyState(
                    title: 'Could not load quests',
                    body: 'Check your connection and try again.',
                    icon: Icons.cloud_off_rounded,
                    actionLabel: 'Try again',
                    onAction: () => ref.invalidate(tasksProvider),
                  ),
                ],
              ),
              data: (rows) => _board(context, rows, now),
            ),
            DockedAction(
              child: QButton(
                label: 'New quest',
                icon: Icons.add_rounded,
                onPressed: () => context.push('/quests/new'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _board(BuildContext context, List<Task> rows, DateTime now) {
    final visible = tasksForBucket(rows, _bucket, _stat, now);
    final counts = {for (final b in QuestBucket.values) b: tasksForBucket(rows, b, _stat, now).length};
    final todayAll = tasksForBucket(rows, QuestBucket.today, null, now);
    final start = DateTime(now.year, now.month, now.day);
    final doneToday = rows.where((t) {
      final at = t.completedAt?.toLocal();
      return t.status == 'done' && at != null && !at.isBefore(start);
    }).length;

    final late = [
      for (final t in visible)
        if (taskIsLate(t, now)) t,
    ];
    final onTime = [
      for (final t in visible)
        if (!taskIsLate(t, now)) t,
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.aboveDockedButton + 40),
      children: [
        _Header(now: now),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: _TodayCard(done: doneToday, open: todayAll.length),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: _Segments(value: _bucket, counts: counts, onChanged: (b) => setState(() => _bucket = b)),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatOrb(label: 'All', selected: _stat == null, onTap: () => setState(() => _stat = null)),
              for (final stat in _stats)
                _StatOrb(
                  stat: stat,
                  label: StatIcon.labelFor(stat),
                  selected: _stat == stat,
                  onTap: () => setState(() => _stat = stat),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (visible.isEmpty)
          EmptyState(
            title: _emptyTitle(_bucket),
            body: _emptyBody(_bucket),
            icon: _bucket == QuestBucket.done ? Icons.task_alt_rounded : Icons.wb_sunny_outlined,
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (late.isNotEmpty) ...[
                  SectionLabel(label: 'Overdue', count: '${late.length}', gemColor: AppColors.error),
                  const SizedBox(height: 14),
                  for (final task in late) ...[
                    _QuestCard(task: task, now: now),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 14),
                ],
                if (onTime.isNotEmpty) ...[
                  SectionLabel(
                    label: _sectionTitle(_bucket),
                    count: '${onTime.length}',
                    gemColor: _bucket == QuestBucket.done ? AppColors.success : AppColors.inkFaint,
                  ),
                  const SizedBox(height: 14),
                  for (final task in onTime) ...[
                    _QuestCard(task: task, now: now),
                    const SizedBox(height: 14),
                  ],
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final kicker = '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, AppSpacing.s20),
      child: ScreenTitle(
        kicker: kicker,
        title: 'Quests',
        trailing: ClayIconButton(
          icon: Icons.add_rounded,
          iconSize: 24,
          tooltip: 'Add',
          onPressed: () => context.push('/quests/new'),
        ),
      ),
    );
  }
}

/// Night-scene summary: how many of today's quests are done.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.done, required this.open});

  final int done;
  final int open;

  @override
  Widget build(BuildContext context) {
    final total = done + open;
    final fraction = total == 0 ? 0.0 : done / total;
    return Semantics(
      label: 'Today: $done of $total quests done',
      excludeSemantics: true,
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const RadialGradient(
            center: Alignment(0.6, -0.65),
            radius: 1.3,
            colors: [AppColors.sceneTop, AppColors.sceneMid, AppColors.sceneDeep],
            stops: [0, 0.48, 1],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0xE6FFFFFF), offset: Offset(-8, -8), blurRadius: 20),
            BoxShadow(color: Color(0x471B1D4F), offset: Offset(12, 14), blurRadius: 30),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TODAY',
                    style: AppText.label.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.3,
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0
                        ? 'A clear board'
                        : open == 0
                        ? 'All quests done'
                        : '$open to go',
                    style: AppText.h1.copyWith(color: AppColors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Every focused minute counts.',
                    style: AppText.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.08)),
                  ),
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: fraction,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      color: AppColors.tealLight,
                      backgroundColor: AppColors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$done',
                              style: AppText.numbers.copyWith(fontSize: 20, color: AppColors.white),
                            ),
                            TextSpan(
                              text: '/$total',
                              style: AppText.numbers.copyWith(
                                fontSize: 13,
                                color: AppColors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'QUESTS',
                        style: AppText.label.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.1,
                          color: AppColors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
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

/// Sunken track with a raised clay thumb that slides to the chosen bucket.
class _Segments extends StatelessWidget {
  const _Segments({required this.value, required this.counts, required this.onChanged});

  final QuestBucket value;
  final Map<QuestBucket, int> counts;
  final ValueChanged<QuestBucket> onChanged;

  @override
  Widget build(BuildContext context) {
    const buckets = QuestBucket.values;
    final index = buckets.indexOf(value);
    return Well(
      height: 48,
      radius: 24,
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / buckets.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppMotion.standard(context),
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: const Clay(kind: ClayKind.control, radius: 20),
              ),
              Row(
                children: [
                  for (final b in buckets)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: b == value,
                        label: '${_bucketLabel(b)}, ${counts[b] ?? 0}',
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => onChanged(b),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _bucketLabel(b),
                                  style: AppText.title.copyWith(
                                    fontSize: 14,
                                    color: b == value ? AppColors.ink : AppColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${counts[b] ?? 0}',
                                  style: AppText.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: b == value ? AppColors.tealDeep : AppColors.inkFaint,
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

/// A round stat filter: white clay, teal clay when selected, label below.
/// The whole orb and its label are tappable.
class _StatOrb extends StatelessWidget {
  const _StatOrb({this.stat, required this.label, required this.selected, required this.onTap});

  final String? stat;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.white : (stat == null ? AppColors.inkMuted : AppColors.stat(stat!));
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Clay(
              kind: selected ? ClayKind.teal : ClayKind.control,
              circle: true,
              width: 52,
              height: 52,
              child: Center(
                child: Icon(
                  stat == null ? Icons.apps_rounded : StatIcon.iconFor(stat!),
                  size: 22,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppText.caption.copyWith(
                color: selected ? AppColors.tealDeep : AppColors.inkMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quest as a clay card: stat gem, title, difficulty and time, due line,
/// and a teal play button for open quests.
class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.task, required this.now});

  final Task task;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final late = taskIsLate(task, now);
    final stat = task.stat ?? 'intellect';
    final due = dueLabel(task, now);
    final done = task.status == 'done';
    final canPlay = task.status == 'open';
    final difficulty = task.difficulty;
    final minutes = task.estMinutes;

    return Semantics(
      button: true,
      label: '${task.title}, $due${task.provisional ? ', provisional' : ''}',
      child: Clay(
        radius: 26,
        onTap: () => context.push('/quests/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Opacity(opacity: done ? 0.55 : 1, child: StatDot(stat: stat, size: 52)),
                  if (late || done)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: done ? AppColors.success : AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: Icon(
                          done ? Icons.check_rounded : Icons.priority_high_rounded,
                          size: 12,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title.copyWith(
                          fontSize: 15,
                          height: 20 / 15,
                          color: done ? AppColors.inkMuted : AppColors.ink,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.inkFaint,
                        ),
                      ),
                      if (difficulty != null || minutes != null || task.provisional) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (difficulty != null) _Pips(value: difficulty),
                            if (difficulty != null && minutes != null) const _Sep(),
                            if (minutes != null) Text('$minutes min', style: AppText.caption),
                            if (task.provisional) ...[
                              const _Sep(),
                              const Icon(Icons.hourglass_empty_rounded, size: 12, color: AppColors.inkFaint),
                              const SizedBox(width: 2),
                              Text('Provisional', style: AppText.caption),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        task.status == 'draft' ? 'Draft · $due' : due,
                        style: AppText.caption.copyWith(
                          color: late ? AppColors.errorText : AppColors.ink,
                          fontWeight: late ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.xpFinal != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '+${task.xpFinal}',
                              style: AppText.numbers.copyWith(fontSize: 14, color: AppColors.tealDeep),
                            ),
                            TextSpan(text: ' XP', style: AppText.caption.copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  if (canPlay)
                    ClayIconButton(
                      kind: ClayKind.teal,
                      icon: Icons.play_arrow_rounded,
                      iconSize: 22,
                      color: AppColors.white,
                      tooltip: 'Start focus',
                      onPressed: () => context.push('/focus/start?taskId=${task.id}'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pips extends StatelessWidget {
  const _Pips({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(1, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < v ? AppColors.tealDeep : AppColors.handle,
              ),
            ),
          ),
      ],
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(color: AppColors.inkFaint, shape: BoxShape.circle),
    );
  }
}

String _bucketLabel(QuestBucket bucket) {
  switch (bucket) {
    case QuestBucket.today:
      return 'Today';
    case QuestBucket.upcoming:
      return 'Upcoming';
    case QuestBucket.done:
      return 'Done';
  }
}

String _sectionTitle(QuestBucket bucket) {
  switch (bucket) {
    case QuestBucket.today:
      return 'Due today';
    case QuestBucket.upcoming:
      return 'Coming up';
    case QuestBucket.done:
      return 'Done';
  }
}

String _emptyTitle(QuestBucket bucket) {
  switch (bucket) {
    case QuestBucket.today:
      return 'Nothing due today';
    case QuestBucket.upcoming:
      return 'No upcoming quests';
    case QuestBucket.done:
      return 'Nothing done yet';
  }
}

String _emptyBody(QuestBucket bucket) {
  switch (bucket) {
    case QuestBucket.today:
      return 'Add a quest and the judge will rate it.';
    case QuestBucket.upcoming:
      return 'Tasks with a later due date show up here.';
    case QuestBucket.done:
      return 'Finished quests will be listed here.';
  }
}
