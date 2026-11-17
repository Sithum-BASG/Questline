import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/timer_display.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/stat_icon.dart';
import '../home/providers/home_providers.dart';
import '../quests/providers/task_providers.dart';
import 'focus_clock.dart';
import 'focus_leave_store.dart';
import 'focus_session_info.dart';
import 'presence_session.dart';
import 'session_alerts.dart';

final endSessionProvider =
    Provider<
      Future<Map<String, dynamic>> Function(
        String sessionId,
        List<Map<String, String>> interruptions, {
        required bool broken,
      })
    >((ref) {
      return (sessionId, interruptions, {required bool broken}) {
        return ref.read(apiClientProvider).endSession(sessionId, interruptions, broken: broken);
      };
    });

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({
    super.key,
    required this.sessionId,
    required this.startedAt,
    required this.estimateMinutes,
    this.mode = 'focus',
    this.stat = 'intellect',
    this.onboarding = false,
    this.grace = const Duration(seconds: 30),
  });

  final String sessionId;
  final DateTime startedAt;
  final int estimateMinutes;
  final String mode;
  final String stat;
  final bool onboarding;
  final Duration grace;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> with WidgetsBindingObserver {
  late final FocusClock _clock;
  late final SessionAlerts _alerts;
  late final FocusPresence _presence;
  final _leaveStore = const FocusLeaveStore();
  Timer? _tick;
  String? _error;
  bool _ending = false;
  bool _confirmOpen = false;
  bool _ongoingInFlight = false;
  String? _lastOngoingLabel;

  @override
  void initState() {
    super.initState();
    _clock = FocusClock(startedAt: widget.startedAt, grace: widget.grace);
    _alerts = ref.read(sessionAlertsProvider);
    _presence = ref.read(focusPresenceProvider);
    _presence.begin(stat: widget.stat, startedAt: widget.startedAt);
    WidgetsBinding.instance.addObserver(this);
    _restoreLeave();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _refreshOngoing();
    });
  }

  Future<void> _restoreLeave() async {
    final left = await _leaveStore.loadLeftAt(widget.sessionId);
    if (!mounted || left == null) return;
    _clock.restoreLeave(left);
    _clock.returned(DateTime.now());
    await _leaveStore.clear();
    if (!mounted) return;
    if (_clock.broken) {
      await _finish(broken: true);
    } else {
      setState(() {});
    }
  }

  /// Focus seconds so far; demo sessions run faster than the wall clock.
  int _elapsed() {
    final real = _clock.elapsedSeconds(DateTime.now());
    return _info?.focusSeconds(real) ?? real;
  }

  Future<void> _refreshOngoing() async {
    final label = TimerDisplay.format(_elapsed());
    if (_ongoingInFlight || label == _lastOngoingLabel) return;
    _ongoingInFlight = true;
    _lastOngoingLabel = label;
    try {
      await _alerts.showOngoing(label, sessionId: widget.sessionId);
    } finally {
      _ongoingInFlight = false;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _alerts.clearOngoing();
    _presence.finish(DateTime.now());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _activity => widget.mode == 'activity';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_activity) return;
    final now = DateTime.now();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_clock.leave(now)) {
        _leaveStore.save(sessionId: widget.sessionId, leftAt: now);
        _alerts.showReturnPrompt(sessionId: widget.sessionId);
      }
    } else if (state == AppLifecycleState.resumed) {
      _clock.returned(now);
      _leaveStore.clear();
      _alerts.clearReturnPrompt();
      if (_clock.broken) {
        _finish(broken: true);
      } else if (mounted) {
        setState(() {});
      }
    }
  }

  double get _minutes => _elapsed() / 60;

  FocusTaskInfo? get _info => ref.read(focusSessionInfoProvider(widget.sessionId)).asData?.value;

  double _minimum(FocusTaskInfo? info) => info?.rates.minEarningMinutes ?? XpRates.defaults.minEarningMinutes;

  int _xpSoFar(FocusTaskInfo? info) =>
      info?.previewXp(_minutes, activity: _activity, usePotion: info.potion, onboarding: widget.onboarding) ?? 0;

  bool _earns(FocusTaskInfo? info) => widget.onboarding || _minutes >= _minimum(info);

  Future<void> _confirmEnd() async {
    if (_ending || _confirmOpen) return;
    _confirmOpen = true;
    final info = _info;
    final xp = _xpSoFar(info);
    final earns = _earns(info);
    final minimum = _minimum(info).round();
    final end = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (context) => _EndDialog(
        body: earns
            ? TextSpan(
                children: [
                  TextSpan(text: "You've done ${_minutes.floor()} min, worth about "),
                  TextSpan(
                    text: '$xp XP',
                    style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '. Ending now completes the quest.'),
                ],
              )
            : TextSpan(text: "Sessions under $minimum minutes don't earn XP or deal damage. Your quest stays open."),
        endLabel: earns && xp > 0 ? 'End and collect $xp XP' : 'End session',
      ),
    );
    _confirmOpen = false;
    if (end == true) await _finish(broken: false);
  }

  /// Finish straight away when the session counts; otherwise explain first.
  Future<void> _finishQuest() async {
    if (_earns(_info)) {
      await _finish(broken: false);
    } else {
      await _confirmEnd();
    }
  }

  Future<void> _finish({required bool broken}) async {
    if (_ending) return;
    setState(() {
      _ending = true;
      _error = null;
    });
    try {
      final interruptions = _clock.interruptions.map((item) => item.toJson()).toList();
      final left = _clock.leftAt;
      if (left != null) interruptions.add({'leftAt': left.toUtc().toIso8601String()});
      final elapsed = _elapsed();
      final summary = await ref.read(endSessionProvider)(widget.sessionId, interruptions, broken: broken);
      // The server may have finished the quest; drop the cached lists so it leaves Quests and Home.
      final taskId = _info?.taskId;
      ref.invalidate(tasksProvider);
      if (taskId != null) ref.invalidate(taskProvider(taskId));
      ref.invalidate(homeSnapshotProvider);
      await _leaveStore.clear();
      _presence.finish(DateTime.now());
      if (!mounted) return;
      context.go(
        '/focus/${widget.sessionId}/complete',
        extra: {
          ...summary,
          'onboarding': widget.onboarding,
          'sessionId': widget.sessionId,
          'elapsedSeconds': elapsed,
          'estimateMinutes': widget.estimateMinutes,
          'mode': widget.mode,
          'graceSeconds': widget.grace.inSeconds,
        },
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _ending = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(focusSessionInfoProvider(widget.sessionId)).asData?.value;
    final real = _clock.elapsedSeconds(DateTime.now());
    final elapsed = info?.focusSeconds(real) ?? real;
    final look = ref.watch(heroLookProvider).asData?.value;
    final stat = info?.stat ?? widget.stat;
    final statLabel = StatIcon.labelFor(stat);
    final estimate = info?.estMinutes ?? widget.estimateMinutes;
    final progress = estimate > 0 ? elapsed / (estimate * 60) : 0.0;
    final potion = info != null && info.potion && !_activity;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEnd();
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final size = box.maxHeight < 720 ? 210.0 : 250.0;
              // Tall screens spread the parts out; short ones scroll with fixed gaps.
              final roomy = box.maxHeight >= 680;
              const padding = EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, AppSpacing.s16);
              final column = Column(
                mainAxisSize: roomy ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        ClayIconButton(
                          icon: Icons.close_rounded,
                          tooltip: 'End session',
                          size: 44,
                          onPressed: _ending ? null : _confirmEnd,
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: AppColors.awakeningTeal, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 7),
                              Semantics(
                                header: true,
                                label: _activity ? 'Activity' : 'Focusing',
                                excludeSemantics: true,
                                child: Text(
                                  _activity ? 'ACTIVITY' : 'FOCUSING',
                                  style: AppText.label.copyWith(
                                    fontSize: 11,
                                    letterSpacing: 1.1,
                                    color: AppColors.tealDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (potion) _PotionPill(multiplier: info.rates.potionMultiplier) else const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  if (roomy) const Spacer() else const SizedBox(height: 20),
                  FocusMedallion(size: size, progress: progress, look: look),
                  const SizedBox(height: 14),
                  Semantics(
                    label: 'Elapsed ${TimerDisplay.format(elapsed)}',
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        TimerDisplay.format(elapsed),
                        style: AppText.timer.copyWith(fontSize: 64, height: 68 / 64, letterSpacing: -2.5),
                      ),
                    ),
                  ),
                  if (estimate > 0)
                    Text(
                      'of ~$estimate min',
                      style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
                    ),
                  if (roomy) const Spacer() else const SizedBox(height: 20),
                  _SessionCard(
                    info: info,
                    stat: stat,
                    statLabel: statLabel,
                    activity: _activity,
                    xp: _xpSoFar(info),
                    damage: info?.previewDamage(_minutes, activity: _activity, onboarding: widget.onboarding) ?? 0,
                    estimate: estimate,
                  ),
                  if (_clock.broken) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Text('Session ended', style: AppText.title.copyWith(color: AppColors.errorText)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    _activity
                        ? 'Lock your phone or play music if you like.'
                        : 'Leaving Questline for over ${widget.grace.inSeconds} seconds ends the session.',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(fontWeight: FontWeight.w400, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 16),
                  QButton(
                    label: 'Finish quest',
                    icon: Icons.check_rounded,
                    loading: _ending,
                    onPressed: _ending ? null : _finishQuest,
                  ),
                ],
              );
              return roomy
                  ? Padding(padding: padding, child: column)
                  : SingleChildScrollView(padding: padding, child: column);
            },
          ),
        ),
      ),
    );
  }
}

String _trim(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

class _PotionPill extends StatelessWidget {
  const _PotionPill({required this.multiplier});

  final double multiplier;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Focus Potion active, ${_trim(multiplier)} times XP',
      excludeSemantics: true,
      child: Clay(
        kind: ClayKind.control,
        radius: 18,
        height: 36,
        padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(GameAssets.icon('focus_potion'), width: 22, height: 22),
            const SizedBox(width: 4),
            Text('${_trim(multiplier)}×', style: AppText.numbers.copyWith(fontSize: 13, color: AppColors.tealDeep)),
          ],
        ),
      ),
    );
  }
}

/// What you're working on, then what it's earning.
class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.info,
    required this.stat,
    required this.statLabel,
    required this.activity,
    required this.xp,
    required this.damage,
    required this.estimate,
  });

  final FocusTaskInfo? info;
  final String stat;
  final String statLabel;
  final bool activity;
  final int xp;
  final int damage;
  final int estimate;

  @override
  Widget build(BuildContext context) {
    final details = info;
    final target = details?.target;
    final subtitle = activity
        ? '$statLabel · activity mode'
        : target != null
        ? '$statLabel · hits ${target.name}'
        : '$statLabel · focus mode';
    final rates = details?.rates ?? XpRates.defaults;
    final cap = ((activity ? rates.activityCapRatio : rates.focusCapRatio) * estimate).round();
    final hpLeft = target == null ? 0 : (target.hpLeft - damage).clamp(0, target.maxHp);
    return Clay(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              ClayDot(
                size: 40,
                gradient: statGradient(stat),
                icon: activity ? Icons.directions_run_rounded : StatIcon.iconFor(stat),
                iconSize: 16,
                semanticLabel: statLabel,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details?.title ?? (activity ? '$statLabel activity' : '$statLabel focus'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(fontSize: 16, height: 21 / 16),
                    ),
                    const SizedBox(height: 1),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppColors.hairline),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FocusTileLabel('XP EARNED'),
                      const SizedBox(height: 3),
                      _Value(value: '+$xp', unit: 'XP', color: AppColors.tealDeep),
                    ],
                  ),
                ),
                Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.hairline),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!activity && target != null) ...[
                        FocusTileLabel(target.raid ? 'RAID DAMAGE' : 'BOSS DAMAGE'),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _Value(value: '$damage', color: AppColors.bossHpText),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Semantics(
                                label: '${target.name} HP',
                                value: '$hpLeft of ${target.maxHp}',
                                excludeSemantics: true,
                                child: ClayBar(
                                  height: 6,
                                  gradient: hpFillGradient,
                                  value: target.maxHp <= 0 ? 0 : hpLeft / target.maxHp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const FocusTileLabel('COUNTS UP TO'),
                        const SizedBox(height: 3),
                        _Value(value: '$cap', unit: 'min'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.value, this.unit, this.color = AppColors.ink});

  final String value;
  final String? unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = AppText.numbers.copyWith(fontSize: 20, height: 24 / 20, letterSpacing: -0.4, color: color);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: value),
          if (unit != null) TextSpan(text: ' $unit', style: style.copyWith(fontSize: 13)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

/// "End this session?" as a clay card over the clock.
class _EndDialog extends StatelessWidget {
  const _EndDialog({required this.body, required this.endLabel});

  final InlineSpan body;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'End this session?',
                textAlign: TextAlign.center,
                style: AppText.h2.copyWith(fontSize: 20, height: 26 / 20),
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              body,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(fontSize: 15, height: 22 / 15, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 22),
            QButton(label: 'Keep going', height: 56, onPressed: () => Navigator.pop(context, false)),
            const SizedBox(height: 12),
            QButton(
              label: endLabel,
              height: 56,
              variant: QButtonVariant.secondary,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
  }
}
