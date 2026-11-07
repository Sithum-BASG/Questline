import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_chip.dart';
import '../social/providers/guild_providers.dart';

const _types = [
  ('assignment', 'Assignment'),
  ('exam', 'Exam'),
  ('project', 'Project'),
];

/// Start a guild fight or party raid: estimate → confirm.
class CreateRaidScreen extends ConsumerStatefulWidget {
  const CreateRaidScreen({super.key});

  @override
  ConsumerState<CreateRaidScreen> createState() => _CreateRaidScreenState();
}

class _CreateRaidScreenState extends ConsumerState<CreateRaidScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  var _source = 'party';
  var _type = 'assignment';
  var _participants = 4;
  DateTime? _deadline;
  var _busy = false;
  String? _error;
  Map<String, dynamic>? _preview;
  double _hours = 6;

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
    final guildId = await ref.read(myGuildIdProvider.future);
    if (_source == 'guild' && guildId == null) {
      setState(() => _error = 'Join a guild before starting a guild fight.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final description = _description.text.trim();
      final json = await ref.read(apiClientProvider).createRaidPreview(
            source: _source,
            guildId: _source == 'guild' ? guildId : null,
            title: title,
            description: description.isEmpty ? null : description,
            type: _type,
            deadline: _deadline!,
            participants: _participants,
          );
      final preview = json['preview'];
      if (preview is! Map) {
        throw const ApiException(code: 'internal', message: 'Could not estimate this raid.');
      }
      final map = Map<String, dynamic>.from(preview);
      if (!mounted) return;
      setState(() {
        _preview = map;
        _hours = (map['perPersonHours'] as num?)?.toDouble() ?? 6;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not estimate this raid. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final preview = _preview;
    final deadline = _deadline;
    if (preview == null || deadline == null) return;
    final guildId = await ref.read(myGuildIdProvider.future);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final description = _description.text.trim();
      final json = await ref.read(apiClientProvider).createRaid(
            source: _source,
            guildId: _source == 'guild' ? guildId : null,
            title: _title.text.trim(),
            description: description.isEmpty ? null : description,
            type: _type,
            deadline: deadline,
            participants: _participants,
            perPersonHours: _hours.roundToDouble().clamp(2, 40),
            name: preview['name'] as String? ?? 'The Shared Deadline',
          );
      final raid = json['raid'];
      if (raid is! Map || raid['id'] is! String) {
        throw const ApiException(code: 'internal', message: 'Could not create this raid.');
      }
      if (!mounted) return;
      final id = raid['id'] as String;
      if (_source == 'party') {
        context.go('/raids/$id/invite');
      } else {
        context.go('/raids/$id');
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not create this raid. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _preview = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final guildAsync = ref.watch(myGuildIdProvider);
    final inGuild = guildAsync.asData?.value != null;
    final preview = _preview;

    return Scaffold(
      appBar: AppBar(
        title: Text(preview == null ? 'Start raid' : 'Confirm raid', style: AppText.h2),
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
          if (preview == null) ...[
            Text('Team type', style: AppText.title),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              children: [
                QChip(
                  label: 'Party',
                  selected: _source == 'party',
                  onTap: _busy ? null : () => setState(() {
                        _source = 'party';
                        _preview = null;
                      }),
                ),
                QChip(
                  label: 'Guild fight',
                  selected: _source == 'guild',
                  onTap: !inGuild || _busy
                      ? null
                      : () => setState(() {
                            _source = 'guild';
                            _preview = null;
                          }),
                ),
              ],
            ),
            if (!inGuild) ...[
              const SizedBox(height: AppSpacing.s8),
              Text('Join a guild to start a guild fight.', style: AppText.caption),
            ],
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              enabled: !_busy,
            ),
            const SizedBox(height: AppSpacing.s12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
              enabled: !_busy,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text('Type', style: AppText.title),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              children: [
                for (final entry in _types)
                  QChip(
                    label: entry.$2,
                    selected: _type == entry.$1,
                    onTap: _busy ? null : () => setState(() => _type = entry.$1),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('Participants: $_participants', style: AppText.title),
            Slider(
              value: _participants.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              label: '$_participants',
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                        _participants = value.round();
                        _preview = null;
                      }),
            ),
            const SizedBox(height: AppSpacing.s8),
            QButton(
              label: _deadline == null
                  ? 'Pick deadline'
                  : 'Deadline ${_deadline!.toLocal()}'.split('.').first,
              variant: QButtonVariant.secondary,
              onPressed: _busy ? null : _pickDeadline,
            ),
            const SizedBox(height: AppSpacing.s24),
            QButton(label: 'Estimate', loading: _busy, onPressed: _busy ? null : _estimate),
          ] else ...[
            Text(preview['name'] as String? ?? 'Raid', style: AppText.h1),
            Text(preview['title'] as String? ?? '', style: AppText.body),
            const SizedBox(height: AppSpacing.s12),
            Text(
              '${preview['tier']} · ${preview['maxHp']} HP · $_participants people',
              style: AppText.bodySmall,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('Per-person hours: ${_hours.round()}', style: AppText.title),
            Slider(
              value: _hours.clamp(2, 40),
              min: 2,
              max: 40,
              divisions: 38,
              label: '${_hours.round()} h',
              onChanged: _busy ? null : (value) => setState(() => _hours = value),
            ),
            if (preview['coinsEligible'] != true)
              Text('Created under 48 hours before the deadline — no coins.', style: AppText.caption),
            const SizedBox(height: AppSpacing.s24),
            QButton(label: 'Start raid', loading: _busy, onPressed: _busy ? null : _confirm),
            const SizedBox(height: AppSpacing.s8),
            QButton(
              label: 'Back',
              variant: QButtonVariant.secondary,
              onPressed: _busy ? null : () => setState(() => _preview = null),
            ),
          ],
        ],
      ),
    );
  }
}
