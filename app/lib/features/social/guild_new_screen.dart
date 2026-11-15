import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/game_config_reader.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/shadows.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/q_button.dart';
import 'guild_emblems.dart';
import 'providers/guild_providers.dart';

/// Members a guild can hold, from game_config.
final guildMaxProvider = FutureProvider<int>((ref) => ref.watch(gameConfigReaderProvider).guildMax());

const _nameMax = 24;

/// Create a guild with a preset emblem, or join with an invite code.
class GuildNewScreen extends ConsumerStatefulWidget {
  const GuildNewScreen({super.key});

  @override
  ConsumerState<GuildNewScreen> createState() => _GuildNewScreenState();
}

class _GuildNewScreenState extends ConsumerState<GuildNewScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  var _emblem = guildEmblemIds.first;
  var _busy = false;
  var _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).createGuild(name: _name.text.trim(), emblem: _emblem);
      ref.invalidate(myGuildIdProvider);
      ref.invalidate(guildHomeProvider);
      if (mounted) context.go('/social/guild');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).joinGuild(_code.text.trim());
      ref.invalidate(myGuildIdProvider);
      ref.invalidate(guildHomeProvider);
      if (mounted) context.go('/social/guild');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = ref.watch(guildMaxProvider).asData?.value ?? 10;
    final name = _name.text.trim();
    return Scaffold(
      appBar: ClayHeader(title: 'Guild', onBack: () => context.go('/social/guild')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s24),
              children: [
                _ModeTabs(
                  joining: _joining,
                  onChanged: _busy
                      ? null
                      : (joining) => setState(() {
                            _joining = joining;
                            _error = null;
                          }),
                ),
                const SizedBox(height: AppSpacing.s24),
                if (!_joining) ...[
                  _BannerPreview(name: name, emblem: _emblem, max: max),
                  const SizedBox(height: AppSpacing.s24),
                  const _FieldLabel('NAME'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    maxLength: _nameMax,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.words,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Name your guild',
                      counterText: '',
                      suffixText: '${_name.text.length} / $_nameMax',
                      suffixStyle: AppText.caption.copyWith(color: AppColors.placeholder),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  const _FieldLabel('EMBLEM'),
                  const SizedBox(height: 10),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    clipBehavior: Clip.none,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 76,
                    ),
                    children: [
                      for (final id in guildEmblemIds)
                        _EmblemTile(
                          id: id,
                          selected: id == _emblem,
                          onTap: _busy ? null : () => setState(() => _emblem = id),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  Text(
                    'You can be in one guild at a time. Invite up to ${max - 1} friends after you create it.',
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),
                ] else ...[
                  Row(
                    children: [
                      const _FieldLabel('INVITE CODE'),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '· from a friend in the guild',
                          style: AppText.caption.copyWith(color: AppColors.placeholder),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _code,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.characters,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600, letterSpacing: 2),
                    decoration: const InputDecoration(hintText: 'ABCD1234'),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Well(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                          child: const Icon(Icons.group_add_rounded, size: 16, color: AppColors.tealDeep),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: AppText.bodySmall.copyWith(fontSize: 13, height: 18 / 13),
                              children: const [
                                TextSpan(
                                  text: 'Need a code? ',
                                  style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: "Ask a friend who's in the guild to share it from their guild page. "
                                      'You need to be friends with the guild leader.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s16),
              child: QButton(
                label: _joining ? 'Join guild' : 'Create guild',
                height: 60,
                loading: _busy,
                onPressed: _busy ? null : (_joining ? _join : _create),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: AppText.label);
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.joining, required this.onChanged});

  final bool joining;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool value) {
      final on = joining == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChanged == null ? null : () => onChanged!(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: on
                  ? const BoxDecoration(
                      gradient: clayWhiteGradient,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      boxShadow: AppShadows.clayControl,
                    )
                  : const BoxDecoration(),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppText.title.copyWith(fontSize: 14, color: on ? AppColors.tealDeep : AppColors.inkMuted),
              ),
            ),
          ),
        ),
      );
    }

    return Well(
      height: 48,
      radius: 24,
      padding: const EdgeInsets.all(4),
      child: Row(children: [tab('Create', false), tab('Join', true)]),
    );
  }
}

class _BannerPreview extends StatelessWidget {
  const _BannerPreview({required this.name, required this.emblem, required this.max});

  final String name;
  final String emblem;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: 30,
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: SizedBox(
          height: 132,
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.56, -0.2),
                      radius: 1.2,
                      colors: [AppColors.sceneTop, AppColors.sceneMid, AppColors.sceneDeep],
                      stops: [0, 0.46, 1],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(child: CustomPaint(painter: _BannerRays())),
              Positioned(left: 22, top: 20, child: GuildEmblem(id: emblem, width: 76)),
              Positioned(
                left: 116,
                right: 14,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEW GUILD',
                      style: AppText.label.copyWith(
                        fontSize: 11,
                        height: 14 / 11,
                        color: AppColors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name.isEmpty ? 'Your guild name' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(
                        fontSize: 20,
                        height: 26 / 20,
                        color: name.isEmpty ? AppColors.white.withValues(alpha: 0.5) : AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '1 / $max members',
                      style: AppText.caption.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerRays extends CustomPainter {
  const _BannerRays();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.22, size.height * 0.4);
    final radius = size.width * 0.6;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.white.withValues(alpha: 0.07), AppColors.white.withValues(alpha: 0)],
        stops: const [0.2, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    const rays = 18;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a))
        ..lineTo(center.dx + radius * math.cos(a + 0.12), center.dy + radius * math.sin(a + 0.12))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BannerRays old) => false;
}

class _EmblemTile extends StatelessWidget {
  const _EmblemTile({required this.id, required this.selected, required this.onTap});

  final String id;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: guildEmblemLabel(id),
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Clay(
              kind: ClayKind.control,
              radius: 22,
              onTap: onTap,
              child: Center(child: GuildEmblem(id: id, width: 40)),
            ),
          ),
          if (selected) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(22)),
                    border: Border.all(color: AppColors.tealDeep, width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -5,
              top: -7,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tealDeep,
                  border: Border.all(color: AppColors.white, width: 3),
                ),
                child: const Icon(Icons.check_rounded, size: 12, color: AppColors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
