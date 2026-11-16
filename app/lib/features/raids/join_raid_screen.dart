import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/notifications/notification_replan.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/boss_card.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/qr_scanner_view.dart';
import '../../core/widgets/q_button.dart';
import '../../data/models/raid.dart';
import '../../data/models/raid_member.dart';
import 'raid_links.dart';
import 'raid_widgets.dart';

/// Party invite codes are eight letters and digits.
const raidCodeLength = 8;

/// Join a party raid by code or QR (optional `?code=` prefill), then preview
/// and join.
class JoinRaidScreen extends ConsumerStatefulWidget {
  const JoinRaidScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  ConsumerState<JoinRaidScreen> createState() => _JoinRaidScreenState();
}

class _JoinRaidScreenState extends ConsumerState<JoinRaidScreen> {
  late final TextEditingController _code;
  final _focus = FocusNode();
  var _busy = false;
  var _scan = false;
  String? _error;

  /// Set once a code was looked up. [_preview] stays null when the raid is
  /// not visible before joining.
  String? _lookedUp;
  Raid? _preview;
  List<RaidMember> _members = const [];

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: _clean(widget.initialCode ?? ''));
    _code.addListener(() => setState(() {}));
    if (_code.text.length == raidCodeLength) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  static String _clean(String raw) {
    final cleaned = raw.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    return cleaned.length > raidCodeLength ? cleaned.substring(0, raidCodeLength) : cleaned;
  }

  Future<void> _lookup() async {
    final code = _clean(_code.text);
    if (code.length < raidCodeLength) {
      setState(() => _error = 'Enter all $raidCodeLength characters of the party code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
      _members = const [];
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final row = await client.from('raids').select().eq('invite_code', code).eq('status', 'active').maybeSingle();
      Raid? raid;
      var members = const <RaidMember>[];
      if (row != null) {
        raid = Raid.fromJson(Map<String, dynamic>.from(row));
        final memberRows = await client.from('raid_members').select().eq('raid_id', raid.id).order('joined_at', ascending: true);
        members = [for (final m in memberRows) RaidMember.fromJson(Map<String, dynamic>.from(m as Map))];
      }
      if (!mounted) return;
      setState(() {
        _lookedUp = code;
        _preview = raid;
        _members = members;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not look up that code. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _lookedUp ?? _clean(_code.text);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final json = await ref.read(apiClientProvider).joinRaid(code: code);
      final raid = json['raid'];
      final id = raid is Map ? raid['id'] as String? : null;
      if (id == null) {
        throw const ApiException(code: 'internal', message: 'Could not join this raid.');
      }
      try {
        await replanLocalNotifications(ref);
      } catch (_) {}
      if (mounted) context.go('/raids/$id');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not join this raid.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onDetect(String raw) {
    if (!_scan) return;
    final uri = Uri.tryParse(raw);
    final fromLink = uri == null ? null : raidCodeFromUri(uri);
    final code = fromLink ?? (RegExp('^[A-Za-z0-9]{$raidCodeLength}\$').hasMatch(raw) ? raw.toUpperCase() : null);
    if (code == null) {
      setState(() => _error = 'That QR is not a Questline party invite.');
      return;
    }
    setState(() {
      _scan = false;
      _code.text = _clean(code);
    });
    _lookup();
  }

  void _back() {
    if (_lookedUp != null) {
      setState(() {
        _lookedUp = null;
        _preview = null;
        _error = null;
      });
    } else {
      context.go('/bosses');
    }
  }

  @override
  Widget build(BuildContext context) {
    final looked = _lookedUp != null;
    return Scaffold(
      appBar: ClayHeader(title: 'Join a party', onBack: _back),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, raidDockClearance(context)),
            children: [
              if (!looked) ...[
                _ModeSwitch(
                  scan: _scan,
                  onChanged: _busy
                      ? null
                      : (scan) => setState(() {
                            _scan = scan;
                            _error = null;
                          }),
                ),
                const SizedBox(height: 28),
                if (_scan) _scanStep() else _codeStep(),
              ] else
                _previewStep(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          if (!_scan || looked)
            RaidDock(
              child: looked
                  ? QButton(
                      label: 'Join the party',
                      icon: Icons.groups_rounded,
                      height: 60,
                      loading: _busy,
                      onPressed: _busy ? null : _join,
                    )
                  : QButton(
                      label: 'Find the party',
                      icon: Icons.search_rounded,
                      height: 60,
                      loading: _busy,
                      onPressed: _busy || _code.text.length < raidCodeLength ? null : _lookup,
                    ),
            ),
        ],
      ),
    );
  }

  Widget _codeStep() {
    final text = _clean(_code.text);
    return Column(
      children: [
        Text('Enter the party code', style: AppText.h1.copyWith(fontSize: 22, height: 28 / 22), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('Eight letters and numbers, from the party leader.', style: AppText.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 26),
        Stack(
          children: [
            // The real field sits under the boxes and takes the typing.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _code,
                  focusNode: _focus,
                  autofocus: widget.initialCode == null,
                  enabled: !_busy,
                  maxLength: raidCodeLength,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    TextInputFormatter.withFunction((old, value) => value.copyWith(text: value.text.toUpperCase())),
                  ],
                  onSubmitted: (_) => _lookup(),
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
            Semantics(
              label: 'Party code',
              value: text,
              child: GestureDetector(
                onTap: () => _focus.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: _CodeBoxes(code: text, active: _focus.hasFocus && !_busy),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text('Got a link instead? Tap it and Questline fills this in.', style: AppText.caption, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _scanStep() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            height: 430,
            child: QrScannerView(onCode: _onDetect, hint: "Point at the QR on your friend's screen"),
          ),
        ),
        const SizedBox(height: 16),
        Text('The camera is only used while this is open.', style: AppText.caption, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _previewStep() {
    final raid = _preview;
    final rules = ref.watch(raidRulesProvider).asData?.value;
    if (raid == null) {
      return Column(
        children: [
          const SizedBox(height: 8),
          Clay(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            child: Column(
              children: [
                ClayDot(size: 56, icon: Icons.groups_rounded, gradient: dotGradient(AppColors.tealLight, AppColors.tealDeep)),
                const SizedBox(height: 14),
                Text('Party code ${_formatCode(_lookedUp!)}', style: AppText.h2, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  'The boss and the party show once you are in.',
                  style: AppText.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Joining uses 1 of your ${rules?.maxFights ?? 15} fight slots.',
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    final now = DateTime.now();
    final hpLeft = (raid.maxHp - raid.damage).clamp(0, raid.maxHp);
    final share = rules?.fairShare(raid.maxHp, raid.participants);
    final loot = rules?.baseLoot(raid.tier);
    final active = _members.where((m) => !m.leftRaid).toList();
    final leader = [for (final m in _members) if (m.userId == raid.createdBy) m.displayName];
    final open = raid.participants - active.length;
    return Column(
      children: [
        if (leader.isNotEmpty) ...[
          Center(child: ClayPill(label: '${leader.first} invited you', icon: Icons.mail_rounded, color: AppColors.tealDeep, onPressed: null)),
          const SizedBox(height: 70),
        ] else
          const SizedBox(height: 90),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Clay(
              radius: 30,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: const SizedBox(height: 130, child: RaidArena(center: Alignment(0, 0.2), floor: Alignment(0, 0.82), floorWidth: 190)),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(raid.name, style: AppText.h2.copyWith(fontSize: 21, height: 27 / 21), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            RaidTierTag(tier: raid.tier),
                            RaidKindTag(guild: raid.source == 'guild'),
                            Text('${raid.title} · ${raidDueLabel(raid.deadline, now)}', style: AppText.caption.copyWith(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final (i, m) in active.take(5).indexed)
                              Align(widthFactor: i == 0 ? 1 : 0.78, child: HeroHead(skinId: m.skinId, bodyType: m.bodyType, size: 36)),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                '${active.length} of ${raid.participants} in'
                                '${open > 0 ? ' · $open ${open == 1 ? 'spot' : 'spots'} left' : ''}',
                                style: AppText.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, thickness: 1, color: AppColors.hairline),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            ValueCell(value: formatCount(hpLeft), label: 'HP', color: AppColors.bossHpText),
                            const ValueDivider(),
                            ValueCell(value: share == null ? '–' : formatCount(share), label: 'YOUR SHARE'),
                            const ValueDivider(),
                            ValueCell(
                              value: loot == null || !raid.coinsEligible ? '0' : formatCount(loot),
                              label: 'LOOT EACH',
                              leading: Image.asset(GameAssets.icon('coin'), width: 20, height: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -84,
              child: IgnorePointer(child: Center(child: BossArt(tier: raid.tier, size: 206))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${share == null ? '' : 'Deal ${formatCount(share)} damage to earn loot. '}'
          'Joining uses 1 of your ${rules?.maxFights ?? 15} fight slots.',
          style: AppText.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

String _formatCode(String code) =>
    code.length == raidCodeLength ? '${code.substring(0, raidCodeLength ~/ 2)}-${code.substring(raidCodeLength ~/ 2)}' : code;

/// "Enter code" / "Scan QR" segmented well.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.scan, required this.onChanged});

  final bool scan;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, IconData icon, bool selected, bool value) {
      final style = AppText.title.copyWith(fontSize: 14, color: selected ? AppColors.ink : AppColors.inkMuted);
      final content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: style.color),
          const SizedBox(width: 6),
          Text(label, style: style),
        ],
      );
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: selected
              ? Clay(kind: ClayKind.control, radius: 20, height: 40, child: content)
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onChanged == null ? null : () => onChanged!(value),
                  child: SizedBox(height: 40, child: content),
                ),
        ),
      );
    }

    return Well(
      radius: 24,
      height: 48,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          segment('Enter code', Icons.keyboard_rounded, !scan, false),
          segment('Scan QR', Icons.qr_code_scanner_rounded, scan, true),
        ],
      ),
    );
  }
}

/// Eight raised boxes with a dash in the middle; the next empty box is a well
/// with a teal ring.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.code, required this.active});

  final String code;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final style = AppText.h1.copyWith(fontSize: 24, height: 28 / 24);
    final next = code.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 5.0;
        const dash = 16.0;
        final width = ((constraints.maxWidth - gap * (raidCodeLength - 2) - dash) / raidCodeLength).clamp(28.0, 46.0);
        final height = width * 1.3;
        Widget box(int i) {
          final char = i < code.length ? code[i] : '';
          if (i == next && active) {
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.well,
                border: Border.all(color: AppColors.teal, width: 2),
              ),
              alignment: Alignment.center,
              child: Container(width: 2, height: height * 0.45, color: AppColors.teal),
            );
          }
          if (char.isEmpty) return Well(radius: 14, width: width, height: height);
          return Clay(
            kind: ClayKind.control,
            radius: 14,
            width: width,
            height: height,
            child: Center(child: Text(char, style: style)),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < raidCodeLength; i++) ...[
              if (i == raidCodeLength ~/ 2)
                Container(
                  width: dash - 8,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: AppColors.chipEdge, borderRadius: BorderRadius.circular(2)),
                )
              else if (i > 0)
                const SizedBox(width: gap),
              box(i),
            ],
          ],
        );
      },
    );
  }
}

