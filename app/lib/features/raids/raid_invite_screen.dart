import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/boss_card.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/q_button.dart';
import 'providers/raid_detail_providers.dart';
import 'raid_links.dart';
import 'raid_widgets.dart';

/// Party invite: a sheet over the raid with the code, a QR and who's in.
class RaidInviteScreen extends ConsumerStatefulWidget {
  const RaidInviteScreen({super.key, required this.raidId});

  final String raidId;

  @override
  ConsumerState<RaidInviteScreen> createState() => _RaidInviteScreenState();
}

class _RaidInviteScreenState extends ConsumerState<RaidInviteScreen> {
  var _copied = false;

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final raidId = widget.raidId;
    final async = ref.watch(raidDetailProvider(raidId));
    void close() => context.go('/raids/$raidId');
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.sceneDeep,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 374 + topInset,
            child: const RaidArena(),
          ),
          if (async.asData?.value case final snap?)
            Positioned(
              left: 0,
              right: 0,
              top: topInset + 40,
              child: IgnorePointer(child: Center(child: BossArt(tier: snap.raid.tier, size: 280))),
            ),
          const Positioned.fill(child: ColoredBox(color: AppColors.scrim)),
          Positioned.fill(
            top: topInset + 52,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.16), offset: const Offset(0, -12), blurRadius: 32)],
              ),
              child: Semantics(
                scopesRoute: true,
                explicitChildNodes: true,
                namesRoute: true,
                label: 'Invite your party',
                child: async.when(
                  loading: () => const LoadingSkeleton(),
                  error: (error, _) => EmptyState(
                    title: 'Could not load invite',
                    body: 'Try again in a moment.',
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(raidDetailProvider(raidId)),
                  ),
                  data: (snap) {
                    final raid = snap?.raid;
                    final code = raid?.inviteCode;
                    if (raid == null || code == null || code.isEmpty) {
                      return EmptyState(
                        title: 'No invite code',
                        body: 'Guild fights notify members in the inbox instead.',
                        actionLabel: 'Open raid',
                        onAction: close,
                      );
                    }
                    final active = snap!.members.where((m) => !m.leftRaid).toList()
                      ..sort((a, b) => (a.userId == snap.myId ? 0 : 1).compareTo(b.userId == snap.myId ? 0 : 1));
                    final seats = raid.participants < active.length ? active.length : raid.participants;
                    return Stack(
                      children: [
                        ListView(
                          padding: EdgeInsets.fromLTRB(AppSpacing.screen, 10, AppSpacing.screen, MediaQuery.paddingOf(context).bottom + 150),
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 5,
                                decoration: BoxDecoration(color: AppColors.handle, borderRadius: BorderRadius.circular(3)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Semantics(
                                        header: true,
                                        child: Text('Invite your party', style: AppText.h1.copyWith(fontSize: 22, height: 28 / 22)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${raid.name} · ${active.length} of ${raid.participants} joined',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ClayIconButton(icon: Icons.close_rounded, tooltip: 'Close', size: 40, onPressed: close),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Semantics(
                              label: 'Party code ${code.split('').join(' ')}',
                              excludeSemantics: true,
                              child: _CodeChars(code: code),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Clay(
                                radius: 30,
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: AppColors.hairline),
                                    ),
                                    child: QrImageView(
                                      data: raidInviteUri(code),
                                      size: 148,
                                      padding: EdgeInsets.zero,
                                      backgroundColor: AppColors.white,
                                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.ink),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.square,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Scan with Questline, or share the code. A Questline account is needed to join.',
                              style: AppText.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Well(
                              radius: 26,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                              child: Wrap(
                                alignment: WrapAlignment.spaceAround,
                                runSpacing: 12,
                                children: [
                                  for (var i = 0; i < seats; i++)
                                    SizedBox(
                                      width: 62,
                                      child: Column(
                                        children: [
                                          if (i < active.length)
                                            HeroHead(skinId: active[i].skinId, bodyType: active[i].bodyType)
                                          else
                                            const EmptySeat(),
                                          const SizedBox(height: 6),
                                          Text(
                                            i >= active.length
                                                ? 'Waiting'
                                                : active[i].userId == snap.myId
                                                    ? 'You'
                                                    : active[i].displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppText.title.copyWith(
                                              fontSize: 12,
                                              height: 16 / 12,
                                              fontWeight: i < active.length ? FontWeight.w600 : FontWeight.w500,
                                              color: i < active.length ? AppColors.ink : AppColors.inkFaint,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          left: AppSpacing.screen,
                          right: AppSpacing.screen,
                          bottom: MediaQuery.paddingOf(context).bottom + 28,
                          child: Column(
                            children: [
                              Text(
                                'Shared text includes the link and the plain code.',
                                style: AppText.caption.copyWith(color: AppColors.inkFaint),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: QButton(
                                      label: _copied ? 'Copied' : 'Copy',
                                      icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                                      variant: QButtonVariant.secondary,
                                      height: 58,
                                      onPressed: () => _copy(code),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 7,
                                    child: QButton(
                                      label: 'Share invite',
                                      icon: Icons.ios_share_rounded,
                                      height: 58,
                                      onPressed: () => SharePlus.instance.share(ShareParams(text: raidInviteShareText(code))),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The code in big raised characters, split in the middle so it reads aloud.
class _CodeChars extends StatelessWidget {
  const _CodeChars({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final half = code.length ~/ 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final width = ((constraints.maxWidth - gap * (code.length - 2) - 20) / code.length).clamp(28.0, 44.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < code.length; i++) ...[
              if (i == half && code.length > 4)
                Container(
                  width: 8,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: AppColors.chipEdge, borderRadius: BorderRadius.circular(2)),
                )
              else if (i > 0)
                const SizedBox(width: gap),
              Clay(
                kind: ClayKind.control,
                radius: 16,
                width: width,
                height: width * 1.23,
                child: Center(child: Text(code[i], style: AppText.h1.copyWith(fontSize: 24, height: 28 / 24))),
              ),
            ],
          ],
        );
      },
    );
  }
}
