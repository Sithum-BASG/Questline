import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_replan.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../data/models/raid.dart';

/// Join a party raid by invite code (optional `?code=` prefill).
class JoinRaidScreen extends ConsumerStatefulWidget {
  const JoinRaidScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  ConsumerState<JoinRaidScreen> createState() => _JoinRaidScreenState();
}

class _JoinRaidScreenState extends ConsumerState<JoinRaidScreen> {
  late final TextEditingController _code;
  var _busy = false;
  String? _error;
  Raid? _preview;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initialCode?.toUpperCase() ?? '');
    if (_code.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 6) {
      setState(() => _error = 'Enter the invite code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final row = await ref
          .read(supabaseClientProvider)
          .from('raids')
          .select()
          .eq('invite_code', code)
          .eq('status', 'active')
          .maybeSingle();
      if (row == null) {
        setState(() => _error = 'No active raid with that code.');
        return;
      }
      setState(() => _preview = Raid.fromJson(Map<String, dynamic>.from(row)));
    } catch (_) {
      setState(() => _error = 'Could not look up that code.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _code.text.trim().toUpperCase();
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

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return Scaffold(
      appBar: AppBar(
        title: Text('Join raid', style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/bosses'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          if (_error != null) ...[
            Text(_error!, style: AppText.bodySmall),
            const SizedBox(height: AppSpacing.s12),
          ],
          TextField(
            controller: _code,
            decoration: const InputDecoration(labelText: 'Invite code'),
            textCapitalization: TextCapitalization.characters,
            enabled: !_busy,
          ),
          const SizedBox(height: AppSpacing.s12),
          QButton(
            label: 'Look up',
            variant: QButtonVariant.secondary,
            loading: _busy && preview == null,
            onPressed: _busy ? null : _lookup,
          ),
          if (preview != null) ...[
            const SizedBox(height: AppSpacing.s16),
            QCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(preview.name, style: AppText.h2),
                  Text(preview.title, style: AppText.body),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    '${preview.participants} seats · due ${preview.deadline.toLocal()}'.split('.').first,
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            QButton(label: 'Join', loading: _busy, onPressed: _busy ? null : _join),
          ],
        ],
      ),
    );
  }
}
