import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../core/widgets/q_chip.dart';
import 'guild_emblems.dart';
import 'providers/guild_providers.dart';

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
  String? _error;

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Create or join', style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/social/guild'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          if (_error != null) ...[
            Text(_error!, style: AppText.bodySmall),
            const SizedBox(height: AppSpacing.s12),
          ],
          QCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create a guild', style: AppText.h2),
                const SizedBox(height: AppSpacing.s12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name (3–24 characters)'),
                  textCapitalization: TextCapitalization.words,
                  enabled: !_busy,
                ),
                const SizedBox(height: AppSpacing.s12),
                Text('Emblem', style: AppText.title),
                const SizedBox(height: AppSpacing.s8),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final id in guildEmblemIds)
                      QChip(
                        label: guildEmblemLabel(id),
                        selected: _emblem == id,
                        onTap: _busy ? null : () => setState(() => _emblem = id),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                QButton(
                  label: 'Create guild',
                  loading: _busy,
                  onPressed: _busy ? null : _create,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          QCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join with a code', style: AppText.h2),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'You must already be friends with the guild leader.',
                  style: AppText.bodySmall,
                ),
                const SizedBox(height: AppSpacing.s12),
                TextField(
                  controller: _code,
                  decoration: const InputDecoration(labelText: 'Invite code'),
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_busy,
                ),
                const SizedBox(height: AppSpacing.s16),
                QButton(
                  label: 'Join guild',
                  variant: QButtonVariant.secondary,
                  loading: _busy,
                  onPressed: _busy ? null : _join,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
