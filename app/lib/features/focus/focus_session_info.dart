import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';

/// The boss or raid a quest hits.
class FocusTarget {
  const FocusTarget({required this.name, required this.damage, required this.maxHp, required this.raid, this.tier = 'brute'});

  final String name;

  /// Boss art tier (minion, brute, warlord, titan).
  final String tier;
  final int damage;
  final int maxHp;
  final bool raid;

  int get hpLeft => math.max(0, maxHp - damage);
}

/// What the focus screens show around a quest: the quest itself, what it hits, your hero and the XP rates.
class FocusTaskInfo {
  const FocusTaskInfo({
    required this.taskId,
    required this.title,
    required this.stat,
    required this.difficulty,
    required this.estMinutes,
    required this.dueAt,
    required this.rescheduled,
    required this.scrollUsed,
    required this.target,
    required this.skinId,
    required this.bodyType,
    required this.streak,
    required this.rates,
    this.potion = false,
  });

  final String taskId;
  final String title;
  final String stat;
  final int difficulty;
  final int estMinutes;
  final DateTime? dueAt;
  final bool rescheduled;
  final bool scrollUsed;
  final FocusTarget? target;
  final String skinId;
  final String bodyType;
  final int streak;
  final XpRates rates;

  /// Whether the session was started with a Focus Potion.
  final bool potion;

  FocusTaskInfo withPotion(bool value) => FocusTaskInfo(
    taskId: taskId,
    title: title,
    stat: stat,
    difficulty: difficulty,
    estMinutes: estMinutes,
    dueAt: dueAt,
    rescheduled: rescheduled,
    scrollUsed: scrollUsed,
    target: target,
    skinId: skinId,
    bodyType: bodyType,
    streak: streak,
    rates: rates,
    potion: value,
  );

  /// Days late if finished [now]; 0 when on time or undated.
  int daysLate(DateTime now) {
    final due = dueAt?.toLocal();
    if (due == null) return 0;
    final dueDay = DateTime(due.year, due.month, due.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(dueDay) ? today.difference(dueDay).inDays : 0;
  }

  /// Timing factor the server applies: on-time bonus, or the late penalty down to its floor.
  double timing(DateTime now) {
    if (dueAt == null) return 1;
    final late = daysLate(now);
    if (late == 0) return 1 + rates.onTimeBonus;
    return math.max(rates.lateFloor, 1 - rates.latePenaltyPerDay * late);
  }

  double get rescheduleFactor => rescheduled && !scrollUsed ? 1 - rates.reschedulePenalty : 1;

  /// Minutes that count for a session of [minutes], capped against the estimate.
  double countedMinutes(double minutes, {required bool activity}) {
    final cap = (activity ? rates.activityCapRatio : rates.focusCapRatio) * estMinutes;
    return estMinutes > 0 ? math.min(minutes, cap) : minutes;
  }

  /// Preview of the XP for [minutes]. The server's number can differ (gear, daily limit).
  int previewXp(
    double minutes, {
    required bool activity,
    required bool usePotion,
    bool onboarding = false,
    DateTime? now,
  }) {
    if (!onboarding && minutes < rates.minEarningMinutes) return 0;
    final counted = countedMinutes(minutes, activity: activity);
    final share = activity ? rates.activityShare : 1.0;
    final raw = _roundHalfUp(
      counted * rates.multiplier(difficulty) * share * timing(now ?? DateTime.now()) * rescheduleFactor,
    );
    final potionOn = usePotion && !activity && counted >= rates.potionMinMinutes;
    return _roundHalfUp(raw * (potionOn ? rates.potionMultiplier : 1));
  }

  /// Boss damage for [minutes]: one per counted focus minute, none in activity mode.
  int previewDamage(double minutes, {required bool activity, bool onboarding = false}) {
    if (activity || target == null) return 0;
    if (!onboarding && minutes < rates.minEarningMinutes) return 0;
    return _roundHalfUp(countedMinutes(minutes, activity: false));
  }
}

int _roundHalfUp(double value) => (value + 0.5).floor();

/// Your hero's look, for the focus clock.
class HeroLook {
  const HeroLook({required this.skinId, required this.bodyType});

  final String skinId;
  final String bodyType;

  BodyType get body => bodyType == 'b' ? BodyType.b : BodyType.a;
}

String _short(String? id, String prefix, String fallback) {
  if (id == null || id.isEmpty) return fallback;
  return id.startsWith(prefix) ? id.substring(prefix.length) : id;
}

final heroLookProvider = FutureProvider.autoDispose<HeroLook>((ref) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  if (uid == null) return const HeroLook(skinId: 'starter', bodyType: 'a');
  final row = await client.from('profiles').select('equipped_skin_id, body_type').eq('id', uid).maybeSingle();
  return HeroLook(
    skinId: _short(row?['equipped_skin_id'] as String?, 'skin_', 'starter'),
    bodyType: row?['body_type'] as String? ?? 'a',
  );
});

int _int(Object? value, [int fallback = 0]) => value is num ? value.round() : fallback;

final focusTaskInfoProvider = FutureProvider.autoDispose.family<FocusTaskInfo?, String>((ref, taskId) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final task = await client
      .from('tasks')
      .select('id, title, stat, difficulty, est_minutes, due_at, rescheduled, scroll_used, boss_id, raid_id')
      .eq('id', taskId)
      .maybeSingle();
  if (task == null) return null;
  FocusTarget? target;
  final bossId = task['boss_id'] as String?;
  final raidId = task['raid_id'] as String?;
  if (bossId != null) {
    final boss = await client.from('bosses').select('name, damage, max_hp, tier').eq('id', bossId).maybeSingle();
    if (boss != null) {
      target = FocusTarget(
        name: boss['name'] as String? ?? 'Boss',
        damage: _int(boss['damage']),
        maxHp: _int(boss['max_hp']),
        raid: false,
        tier: boss['tier'] as String? ?? 'brute',
      );
    }
  } else if (raidId != null) {
    final raid = await client.from('raids').select('name, damage, max_hp, tier').eq('id', raidId).maybeSingle();
    if (raid != null) {
      target = FocusTarget(
        name: raid['name'] as String? ?? 'Raid',
        damage: _int(raid['damage']),
        maxHp: _int(raid['max_hp']),
        raid: true,
        tier: raid['tier'] as String? ?? 'brute',
      );
    }
  }
  final look = await ref.watch(heroLookProvider.future);
  final player = await client.from('player_state').select('streak_count').maybeSingle();
  final rates = await ref.read(gameConfigReaderProvider).xpRates();
  final due = task['due_at'];
  return FocusTaskInfo(
    taskId: task['id'] as String,
    title: task['title'] as String? ?? 'Quest',
    stat: task['stat'] as String? ?? 'intellect',
    difficulty: _int(task['difficulty'], 1),
    estMinutes: _int(task['est_minutes']),
    dueAt: due is String ? DateTime.tryParse(due) : null,
    rescheduled: task['rescheduled'] == true,
    scrollUsed: task['scroll_used'] == true,
    target: target,
    skinId: look.skinId,
    bodyType: look.bodyType,
    streak: _int(player?['streak_count']),
    rates: rates,
  );
});

/// The quest behind a session, with whether it used a potion.
final focusSessionInfoProvider = FutureProvider.autoDispose.family<FocusTaskInfo?, String>((ref, sessionId) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final session = await client.from('sessions').select('task_id, potion').eq('id', sessionId).maybeSingle();
  final taskId = session?['task_id'] as String?;
  if (taskId == null) return null;
  final info = await ref.watch(focusTaskInfoProvider(taskId).future);
  return info?.withPotion(session?['potion'] == true);
});

enum FocusRing { live, full, stopped, idle }

/// The clock's sunken track: a softer bottom-right highlight than other wells, so the white ring's
/// inner edge stays visible there.
const List<InnerShadow> _trackShade = [
  InnerShadow(Offset(4, 4), 10, Color(0x24101935)),
  InnerShadow(Offset(-3, -3), 8, Color(0x80FFFFFF)),
];

/// The clay focus clock with your hero standing inside it, head and shoulders rising out of the top.
///
/// Drawn on a 260 px grid and scaled to [size]. The widget's height includes the headroom above the clock.
class FocusMedallion extends StatelessWidget {
  const FocusMedallion({
    super.key,
    required this.size,
    required this.progress,
    this.ring = FocusRing.live,
    this.look,
    this.faceGlow,
  });

  final double size;
  final double progress;
  final FocusRing ring;
  final HeroLook? look;
  final Color? faceGlow;

  static double headroomFor(double size) => 90 * size / 260;

  @override
  Widget build(BuildContext context) {
    final s = size / 260;
    final headroom = headroomFor(size);
    final glow = faceGlow ?? AppColors.rare;
    final hero = look;
    return SizedBox(
      width: size,
      height: size + headroom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: headroom,
            width: size,
            height: size,
            child: Stack(
              children: [
                // A deeper drop shadow and a faint rim so the white ring stands out from the page.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.16),
                          offset: Offset(0, 16 * s),
                          blurRadius: 34 * s,
                        ),
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.08),
                          offset: Offset(0, 3 * s),
                          blurRadius: 6 * s,
                        ),
                      ],
                    ),
                  ),
                ),
                Clay(circle: true, width: size, height: size),
                Positioned.fill(child: CustomPaint(painter: _RimPainter(scale: s))),
                Positioned(
                  left: 16 * s,
                  top: 16 * s,
                  child: Well(circle: true, width: 228 * s, height: 228 * s, shade: _trackShade),
                ),
                Positioned(
                  left: 16 * s,
                  top: 16 * s,
                  width: 228 * s,
                  height: 228 * s,
                  child: CustomPaint(
                    painter: _RingPainter(progress: progress, ring: ring, scale: s),
                  ),
                ),
                Positioned(
                  left: 42 * s,
                  top: 42 * s,
                  width: 176 * s,
                  height: 176 * s,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.white, AppColors.focusFaceFoot],
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.16),
                          colors: [
                            glow.withValues(alpha: ring == FocusRing.stopped ? 0 : 0.20),
                            glow.withValues(alpha: ring == FocusRing.stopped ? 0 : 0.06),
                            glow.withValues(alpha: 0),
                          ],
                          stops: const [0, 0.45, 0.7],
                        ),
                      ),
                      child: const CustomPaint(
                        painter: InnerShadowPainter(
                          circle: true,
                          shadows: [
                            InnerShadow(Offset(3, 4), 10, Color(0x1A101935)),
                            InnerShadow(Offset(-3, -3), 8, Color(0xFFFFFFFF)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hero != null)
            Positioned(
              left: 0,
              top: 0,
              width: size,
              height: size + headroom,
              child: IgnorePointer(
                child: _HeroCutout(look: hero, size: size, greyed: ring == FocusRing.stopped),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCutout extends StatelessWidget {
  const _HeroCutout({required this.look, required this.size, required this.greyed});

  final HeroLook look;
  final double size;
  final bool greyed;

  @override
  Widget build(BuildContext context) {
    final s = size / 260;
    final headroom = FocusMedallion.headroomFor(size);
    final imageWidth = 410 * s;
    final scale = imageWidth / GameAssets.stageCanvas.width;
    final crop = GameAssets.portraitCrop(look.skinId, look.body);
    final left = size / 2 - crop.center.dx * scale;
    final top = headroom + (look.body == BodyType.b ? -60 : -42) * s;
    Widget image = Image.asset(
      GameAssets.skin(look.skinId, look.body),
      width: imageWidth,
      height: imageWidth * 1.5,
      fit: BoxFit.fill,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    if (greyed) {
      image = ColorFiltered(colorFilter: const ColorFilter.matrix(_greyMatrix), child: image);
    }
    return ClipPath(
      clipper: _HeroClip(scale: s, headroom: headroom),
      child: Stack(
        clipBehavior: Clip.none,
        children: [Positioned(left: left, top: top, child: image)],
      ),
    );
  }
}

/// 35% greyscale.
const List<double> _greyMatrix = [
  0.7244, 0.2503, 0.0253, 0, 0, //
  0.0744, 0.9003, 0.0253, 0, 0, //
  0.0744, 0.2503, 0.6753, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// The inner circle of the clock plus a column above it, so only the head and shoulders rise out.
class _HeroClip extends CustomClipper<Path> {
  _HeroClip({required this.scale, required this.headroom});

  final double scale;
  final double headroom;

  @override
  Path getClip(Size size) {
    final centre = Offset(130 * scale, headroom + 130 * scale);
    return Path()
      ..addOval(Rect.fromCircle(center: centre, radius: 88 * scale))
      ..addRect(Rect.fromLTRB(80 * scale, 0, 180 * scale, centre.dy));
  }

  @override
  bool shouldReclip(_HeroClip oldClipper) => oldClipper.scale != scale || oldClipper.headroom != headroom;
}

/// Hairlines on the outer edge of the white ring and where it meets the sunken track.
class _RimPainter extends CustomPainter {
  _RimPainter({required this.scale});

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.ink.withValues(alpha: 0.08);
    canvas.drawCircle(centre, 130 * scale - 0.5, rim);
    // The track's highlight sits on its bottom right and washes into the white ring there,
    // so the inner edge darkens toward the bottom right.
    // A soft blurred shade rather than a line, so it blends into the track.
    final inner = 114 * scale;
    canvas.drawCircle(
      centre,
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * scale
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * scale)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.ink.withValues(alpha: 0),
            AppColors.ink.withValues(alpha: 0.04),
            AppColors.ink.withValues(alpha: 0.12),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: inner)),
    );
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) => oldDelegate.scale != scale;
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.ring, required this.scale});

  final double progress;
  final FocusRing ring;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = 104 * scale;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final stroke = 10 * scale;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    switch (ring) {
      case FocusRing.idle:
        paint
          ..color = AppColors.focusRingIdle
          ..strokeCap = StrokeCap.butt;
        final dash = 3 * scale / radius;
        final gap = 9.6 * scale / radius;
        for (var a = 0.0; a < math.pi * 2; a += dash + gap) {
          canvas.drawArc(rect, a, dash, false, paint);
        }
      case FocusRing.full:
        paint.shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tealLight, AppColors.focusRingDeep],
        ).createShader(rect);
        canvas.drawCircle(centre, radius, paint);
      case FocusRing.live:
        final value = progress.clamp(0.0, 1.0);
        if (value <= 0) return;
        paint.shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tealLight, AppColors.focusRingDeep],
        ).createShader(rect);
        canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, paint);
      case FocusRing.stopped:
        final value = progress.clamp(0.0, 1.0);
        paint.color = AppColors.focusRingStopped;
        if (value > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, paint);
        final angle = -math.pi / 2 + math.pi * 2 * value;
        final notch = centre + Offset(math.cos(angle), math.sin(angle)) * radius;
        final r = 13 * scale;
        canvas.drawCircle(
          notch + Offset(1 * scale, 2 * scale),
          r,
          Paint()
            ..color = AppColors.ink.withValues(alpha: 0.25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * scale),
        );
        canvas.drawCircle(notch, r, Paint()..color = AppColors.white);
        canvas.drawCircle(
          notch,
          r - 3 * scale,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.emberLight, AppColors.emberDeep],
            ).createShader(Rect.fromCircle(center: notch, radius: r)),
        );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.ring != ring || oldDelegate.scale != scale;
}

/// Small uppercase label used on the focus cards.
class FocusTileLabel extends StatelessWidget {
  const FocusTileLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.label.copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 0.66, color: AppColors.inkMuted),
    );
  }
}
