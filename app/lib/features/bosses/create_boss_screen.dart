import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/notifications/notification_replan.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/q_button.dart';
import 'providers/boss_providers.dart';

const _types = [
  ('assignment', 'Assignment', Icons.description_rounded),
  ('exam', 'Exam', Icons.school_rounded),
  ('project', 'Project', Icons.layers_rounded),
];

/// Boss tiers (name, hours below which it applies, defeat coins), the hours range and the coin cut-off.
class _BossRules {
  const _BossRules({required this.tiers, required this.minHours, required this.maxHours, required this.coinHours});

  final List<(String, double, int)> tiers;
  final double minHours;
  final double maxHours;

  /// Bosses made closer than this to the deadline pay no coins.
  final int coinHours;

  (String, int) tierFor(double hours) {
    for (final (name, below, coins) in tiers) {
      if (hours < below) return (name, coins);
    }
    return (tiers.last.$1, tiers.last.$3);
  }

  static const defaults = _BossRules(
    tiers: [('minion', 4, 100), ('brute', 12, 150), ('warlord', 25, 200), ('titan', 999, 300)],
    minHours: 2,
    maxHours: 40,
    coinHours: 48,
  );
}

final _bossRulesProvider = FutureProvider.autoDispose<_BossRules>((ref) async {
  final reader = ref.read(gameConfigReaderProvider);
  final map = await reader.load();
  double d(String key, double fallback) => map[key] is num ? (map[key] as num).toDouble() : fallback;
  return _BossRules(
    tiers: await reader.bossTiers(),
    minHours: d('boss_hours_min', 2),
    maxHours: d('boss_hours_max', 40),
    coinHours: d('boss_min_hours_before_deadline_for_coins', 48).round(),
  );
});

const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _date(DateTime d) => '${_wd[d.weekday - 1]} ${d.day} ${_mo[d.month - 1]}';

String _time(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}';
}

String _inDays(DateTime deadline) {
  final diff = deadline.difference(DateTime.now());
  if (diff.inDays >= 2) return 'in ${diff.inDays} days';
  if (diff.inHours >= 24) return 'tomorrow';
  if (diff.inHours >= 1) return 'in ${diff.inHours} h';
  return 'soon';
}

String _thousands(int value) {
  final s = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

String _cap(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

/// Details → the AI names the boss and estimates the hours → adjust and summon.
class CreateBossScreen extends ConsumerStatefulWidget {
  const CreateBossScreen({super.key});

  @override
  ConsumerState<CreateBossScreen> createState() => _CreateBossScreenState();
}

class _CreateBossScreenState extends ConsumerState<CreateBossScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  var _type = 'assignment';
  DateTime? _deadline;
  var _busy = false;
  String? _error;

  Map<String, dynamic>? _preview;
  double _hours = 6;
  double _aiHours = 6;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

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
    final description = _description.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final json = await ref.read(apiClientProvider).createBossPreview(
            title: title,
            description: description.isEmpty ? null : description,
            type: _type,
            deadline: _deadline!,
          );
      final preview = json['preview'];
      if (preview is! Map) {
        throw const ApiException(code: 'internal', message: 'Could not estimate this boss.');
      }
      final map = Map<String, dynamic>.from(preview);
      if (!mounted) return;
      setState(() {
        _preview = map;
        _hours = (map['hours'] as num?)?.toDouble() ?? 6;
        _aiHours = _hours;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not estimate this boss. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _summon(_BossRules rules) async {
    final preview = _preview;
    final deadline = _deadline;
    if (preview == null || deadline == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final description = _description.text.trim();
      final json = await ref.read(apiClientProvider).createBoss(
            title: _title.text.trim(),
            description: description.isEmpty ? null : description,
            type: _type,
            deadline: deadline,
            hours: _hours.roundToDouble().clamp(rules.minHours, rules.maxHours),
            name: preview['name'] as String? ?? 'The Deadline Shade',
          );
      final boss = json['boss'];
      if (boss is! Map || boss['id'] is! String) {
        throw const ApiException(code: 'internal', message: 'Could not create this boss.');
      }
      ref.invalidate(bossesProvider);
      try {
        await replanLocalNotifications(ref);
      } catch (_) {}
      if (!mounted) return;
      context.go('/bosses/${boss['id']}');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not create this boss. Try again.');
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
      initialTime: TimeOfDay.fromDateTime(_deadline ?? date.add(const Duration(hours: 17))),
    );
    if (time == null || !mounted) return;
    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _preview = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(_bossRulesProvider).asData?.value ?? _BossRules.defaults;
    final summoning = _preview != null;
    final insets = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: summoning ? _summonStep(rules, insets) : _detailsStep(insets)),
          Positioned(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            top: insets.top + 9,
            child: _Header(
              summoning: summoning,
              onBack: () {
                if (summoning) {
                  setState(() => _preview = null);
                } else {
                  context.go('/bosses');
                }
              },
            ),
          ),
          Positioned(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            bottom: insets.bottom + 20,
            child: summoning
                ? QButton(
                    label: _busy ? 'Summoning…' : 'Summon the boss',
                    icon: _busy ? null : Icons.auto_awesome_rounded,
                    loading: _busy,
                    onPressed: _busy ? null : () => _summon(rules),
                  )
                : Opacity(
                    opacity: _busy || (_title.text.trim().isNotEmpty && _deadline != null) ? 1 : 0.45,
                    child: QButton(
                      label: _busy ? 'Estimating…' : 'Estimate the boss',
                      icon: _busy ? null : Icons.auto_awesome_rounded,
                      loading: _busy,
                      onPressed: _busy ? null : _estimate,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailsStep(EdgeInsets insets) {
    final deadline = _deadline;
    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, insets.top + 69, AppSpacing.screen, insets.bottom + 110),
      children: [
        Center(child: _SummoningCircle(reading: _busy)),
        const SizedBox(height: 22),
        Clay(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('THE DEADLINE', style: AppText.label),
              const SizedBox(height: 6),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                onChanged: (_) => setState(() => _preview = null),
                style: AppText.h2.copyWith(fontSize: 19, height: 25 / 19, fontWeight: FontWeight.w600),
                decoration: _bare('What is due?', AppText.h2.copyWith(fontSize: 19, height: 25 / 19, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
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
                      controller: _description,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      style: AppText.body.copyWith(fontSize: 14, height: 20 / 14),
                      decoration: _bare('What it involves (optional)', AppText.body.copyWith(fontSize: 14, height: 20 / 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('TYPE', style: AppText.label),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (id, label, icon) in _types) ...[
              if (id != _types.first.$1) const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: _type == id,
                  label: label,
                  excludeSemantics: true,
                  child: Clay(
                    kind: _type == id ? ClayKind.teal : ClayKind.control,
                    radius: 24,
                    height: 48,
                    onTap: () => setState(() {
                      _type = id;
                      _preview = null;
                    }),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 16, color: _type == id ? AppColors.white : AppColors.ink),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(fontSize: 14, color: _type == id ? AppColors.white : AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'DEADLINE'),
            TextSpan(
              text: "  · when it's handed in",
              style: AppText.caption.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0, color: AppColors.inkFaint),
            ),
          ]),
          style: AppText.label,
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: deadline == null ? 'Pick a deadline' : 'Deadline ${_date(deadline)} ${_time(deadline)}, ${_inDays(deadline)}',
          excludeSemantics: true,
          child: Clay(
            kind: ClayKind.control,
            radius: 22,
            height: 56,
            onTap: _busy ? null : _pickDeadline,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.tealDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    deadline == null ? 'Pick a date and time' : '${_date(deadline)} · ${_time(deadline)}',
                    style: AppText.title.copyWith(fontSize: 15, color: deadline == null ? AppColors.inkMuted : AppColors.ink),
                  ),
                ),
                if (deadline != null) Text(_inDays(deadline), style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        if (_error != null) ...[
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.tealDeep),
            const SizedBox(width: 6),
            Flexible(
              child: Text('The AI estimates the hours and names your boss.', style: AppText.bodySmall.copyWith(height: 18 / 13)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summonStep(_BossRules rules, EdgeInsets insets) {
    final preview = _preview!;
    final deadline = _deadline!;
    final (tier, coins) = rules.tierFor(_hours);
    final safeTier = GameAssets.bossTiers.contains(tier) ? tier : 'brute';
    final late = deadline.difference(DateTime.now()).inHours < rules.coinHours;
    final artSize = const {'minion': 220.0, 'brute': 240.0, 'warlord': 250.0, 'titan': 262.0}[safeTier]!;
    final name = preview['name'] as String? ?? 'Boss';
    final typeLabel = _types.firstWhere((t) => t.$1 == _type).$2;
    final fieldHeight = insets.top + 313;
    return ListView(
      padding: EdgeInsets.only(bottom: insets.bottom + 110),
      children: [
        SizedBox(
          height: fieldHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: _Arena()),
              Positioned(
                left: 0,
                right: 0,
                top: fieldHeight - 60,
                child: Center(
                  child: Container(
                    width: 200,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: const BorderRadius.all(Radius.elliptical(100, 20)),
                      gradient: RadialGradient(
                        colors: [
                          AppColors.bossHp.withValues(alpha: 0.6),
                          AppColors.bossHp.withValues(alpha: 0.22),
                          AppColors.bossHp.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: fieldHeight - 30 - artSize * 0.96,
                child: Center(
                  child: Semantics(
                    image: true,
                    label: '$name, ${_cap(tier)} tier',
                    child: Image.asset(GameAssets.boss(safeTier), width: artSize, height: artSize),
                  ),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Clay(
                  radius: 30,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.tealDeep),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'NAMED BY THE AI',
                              style: AppText.label.copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 1.1, color: AppColors.tealDeep),
                            ),
                          ),
                          Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            decoration: BoxDecoration(color: AppColors.raidInk, borderRadius: BorderRadius.circular(11)),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                tier.toUpperCase(),
                                style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1, color: AppColors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Semantics(
                        header: true,
                        child: Text(name, style: AppText.h1.copyWith(fontSize: 23, height: 29 / 23, letterSpacing: -0.7)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_title.text.trim()} · $typeLabel · due ${_date(deadline)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 14),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            _Value(value: _thousands((_hours.round() * 60)), label: 'HP', color: AppColors.bossHpText),
                            const VerticalDivider(width: 1, thickness: 1, color: AppColors.hairline),
                            _Value(value: '${_hours.round()}', unit: 'h', label: 'OF WORK'),
                            const VerticalDivider(width: 1, thickness: 1, color: AppColors.hairline),
                            _Value(value: '$coins', label: 'DEFEAT LOOT', coin: true, struck: late),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(child: Text('HOURS OF WORK', style: AppText.label)),
                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'AI estimate '),
                        TextSpan(text: '${_aiHours.round()} h', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                      ]),
                      style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _HoursSlider(
                  rules: rules,
                  value: _hours,
                  aiValue: _aiHours,
                  tier: tier,
                  onChanged: _busy ? null : (v) => setState(() => _hours = v),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${rules.minHours.round()} h', style: AppText.caption.copyWith(fontSize: 11, color: AppColors.inkFaint)),
                    const Spacer(),
                    Text('${rules.maxHours.round()} h', style: AppText.caption.copyWith(fontSize: 11, color: AppColors.inkFaint)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Fewer hours means less HP and less loot. Adjust it if the estimate feels off.',
                  style: AppText.bodySmall.copyWith(height: 18 / 13),
                ),
                const SizedBox(height: 14),
                if (late)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: AppColors.bossLateSoft, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 18, color: AppColors.bossHpText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'No coins for this boss. ', style: TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: 'The deadline is under ${rules.coinHours} hours away.'),
                            ]),
                            style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.bossHpText),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Clay(
                    kind: ClayKind.control,
                    radius: 24,
                    height: 48,
                    onTap: () => context.go('/raids/new'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 14, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 18, color: AppColors.raidInk),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: 'Fight it with friends? ', style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                              TextSpan(text: 'Start a raid', style: AppText.title.copyWith(fontSize: 13, color: AppColors.tealDeep)),
                            ]),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkFaint),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _bare(String hint, TextStyle style) => InputDecoration(
      hintText: hint,
      hintStyle: style.copyWith(color: AppColors.placeholder),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      isDense: true,
      contentPadding: EdgeInsets.zero,
    );

class _Header extends StatelessWidget {
  const _Header({required this.summoning, required this.onBack});

  final bool summoning;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          ClayIconButton(
            kind: summoning ? ClayKind.onScene : ClayKind.control,
            icon: Icons.chevron_left_rounded,
            iconSize: 24,
            size: 44,
            tooltip: 'Back',
            onPressed: onBack,
          ),
          Expanded(
            child: Center(
              child: summoning
                  ? Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.8), width: 1.5),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          'NEW BOSS',
                          style: AppText.label.copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 1.5, color: AppColors.raidInk),
                        ),
                      ),
                    )
                  : Semantics(
                      header: true,
                      child: Text('Summon a boss', style: AppText.title.copyWith(fontSize: 17, height: 22 / 17)),
                    ),
            ),
          ),
          Semantics(
            label: 'Step ${summoning ? 2 : 1} of 2',
            excludeSemantics: true,
            child: SizedBox(
              width: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _StepDot(on: !summoning, dim: summoning),
                  const SizedBox(width: 5),
                  _StepDot(on: summoning, dim: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.on, required this.dim});

  final bool on;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: on ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: on ? AppColors.tealDeep : (dim ? AppColors.raidInk.withValues(alpha: 0.3) : AppColors.focusRingIdle),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// The summoning circle: an unknown shape waits in the portal until the AI names it.
class _SummoningCircle extends StatelessWidget {
  const _SummoningCircle({required this.reading});

  final bool reading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 190,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Clay(
            circle: true,
            width: 176,
            height: 176,
            padding: const EdgeInsets.all(8),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _Arena(),
                  Center(
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.75), width: 1.5),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: Center(
                      child: Container(
                        width: 104,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.elliptical(52, 11)),
                          gradient: RadialGradient(
                            colors: [AppColors.bossHp.withValues(alpha: 0.5), AppColors.bossHp.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Opacity(
                      opacity: reading ? 0.35 : 0.22,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(AppColors.ink, BlendMode.srcIn),
                        child: Image.asset(GameAssets.boss('brute'), width: 120, height: 120),
                      ),
                    ),
                  ),
                  const Center(child: Icon(Icons.question_mark_rounded, size: 30, color: AppColors.white)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 162,
            child: Clay(
              kind: ClayKind.control,
              radius: 14,
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                reading ? 'READING THE DEADLINE…' : 'AWAITING A NAME',
                style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1.2, color: AppColors.raidInk),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lavender arena glow with soft rays.
class _Arena extends StatelessWidget {
  const _Arena();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, 0.24),
          radius: 0.95,
          colors: [AppColors.arenaLight, AppColors.arenaMid, AppColors.arenaDeep],
          stops: [0, 0.42, 1],
        ),
      ),
      child: CustomPaint(painter: _ArenaRays()),
    );
  }
}

class _ArenaRays extends CustomPainter {
  const _ArenaRays();

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.62);
    final radius = size.longestSide * 0.75;
    final rect = Rect.fromCircle(center: origin, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.white.withValues(alpha: 0.24), AppColors.white.withValues(alpha: 0)],
        stops: const [0.1, 0.6],
      ).createShader(rect);
    const on = 7 * math.pi / 180;
    const step = 20 * math.pi / 180;
    for (var a = 0.0; a < math.pi * 2; a += step) {
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy)
          ..arcTo(rect, a, on, false)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArenaRays oldDelegate) => false;
}

class _Value extends StatelessWidget {
  const _Value({required this.value, required this.label, this.unit, this.color = AppColors.ink, this.coin = false, this.struck = false});

  final String value;
  final String? unit;
  final String label;
  final Color color;
  final bool coin;
  final bool struck;

  @override
  Widget build(BuildContext context) {
    final style = AppText.numbers.copyWith(
      fontSize: 20,
      height: 24 / 20,
      letterSpacing: -0.4,
      color: struck ? AppColors.inkFaint : color,
      decoration: struck ? TextDecoration.lineThrough : null,
    );
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (coin) ...[
                  Opacity(opacity: struck ? 0.4 : 1, child: Image.asset(GameAssets.icon('coin'), width: 20, height: 20)),
                  const SizedBox(width: 4),
                ],
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: value),
                    if (unit != null) TextSpan(text: unit, style: style.copyWith(fontSize: 13, color: AppColors.inkMuted)),
                  ]),
                  style: style,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}

/// One slider across the tier zones, with the AI's estimate marked under it.
class _HoursSlider extends StatelessWidget {
  const _HoursSlider({required this.rules, required this.value, required this.aiValue, required this.tier, required this.onChanged});

  final _BossRules rules;
  final double value;
  final double aiValue;
  final String tier;
  final ValueChanged<double>? onChanged;

  double _fraction(double hours) => ((hours - rules.minHours) / (rules.maxHours - rules.minHours)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    // Zone edges in hours, clipped to the slider range.
    final zones = <(String, double, double)>[];
    var start = rules.minHours;
    for (final (name, below, _) in rules.tiers) {
      final end = math.min(below, rules.maxHours);
      if (end > start) zones.add((name, start, end));
      start = math.max(start, end);
      if (start >= rules.maxHours) break;
    }
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        void update(double dx) {
          final f = (dx / w).clamp(0.0, 1.0);
          onChanged?.call((rules.minHours + f * (rules.maxHours - rules.minHours)).roundToDouble());
        }

        return Semantics(
          slider: true,
          label: 'Hours of work',
          value: '${value.round()} hours, ${_cap(tier)}',
          increasedValue: '${math.min(rules.maxHours, value + 1).round()} hours',
          decreasedValue: '${math.max(rules.minHours, value - 1).round()} hours',
          onIncrease: onChanged == null ? null : () => onChanged!(math.min(rules.maxHours, value.roundToDouble() + 1)),
          onDecrease: onChanged == null ? null : () => onChanged!(math.max(rules.minHours, value.roundToDouble() - 1)),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => update(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
            child: SizedBox(
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (name, from, to) in zones)
                    if (_fraction(to) - _fraction(from) > 0.12)
                      Positioned(
                        left: w * (_fraction(from) + _fraction(to)) / 2 - 40,
                        width: 80,
                        top: -22,
                        child: Text(
                          name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppText.label.copyWith(
                            fontSize: 10,
                            height: 12 / 10,
                            letterSpacing: 0.6,
                            color: name == tier ? AppColors.raidInk : AppColors.inkFaint,
                          ),
                        ),
                      ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 14,
                    child: Well(
                      radius: 7,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Stack(
                          children: [
                            for (final (i, (_, from, to)) in zones.indexed)
                              Positioned(
                                left: w * _fraction(from),
                                width: w * (_fraction(to) - _fraction(from)),
                                top: 0,
                                bottom: 0,
                                child: ColoredBox(
                                  color: AppColors.bossTierZones[math.min(i + (4 - zones.length).clamp(0, 3), 3)],
                                ),
                              ),
                            for (final (_, from, _) in zones.skip(1))
                              Positioned(
                                left: w * _fraction(from) - 1,
                                width: 2,
                                top: 0,
                                bottom: 0,
                                child: const ColoredBox(color: AppColors.white),
                              ),
                            Positioned(
                              left: 0,
                              width: w * _fraction(value),
                              top: 0,
                              bottom: 0,
                              child: const DecoratedBox(decoration: BoxDecoration(gradient: hpFillGradient)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * _fraction(aiValue) - 5,
                    top: 18,
                    child: CustomPaint(size: const Size(10, 6), painter: const _Marker()),
                  ),
                  Positioned(
                    left: w * _fraction(value) - 15,
                    top: -8,
                    child: Clay(
                      kind: ClayKind.control,
                      circle: true,
                      width: 30,
                      height: 30,
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: AppColors.bossHp, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The small teal triangle under the AI's estimate.
class _Marker extends CustomPainter {
  const _Marker();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = AppColors.tealDeep,
    );
  }

  @override
  bool shouldRepaint(_Marker oldDelegate) => false;
}
