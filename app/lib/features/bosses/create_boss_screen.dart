import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_chip.dart';
import 'providers/boss_providers.dart';

const _types = [
  ('assignment', 'Assignment'),
  ('exam', 'Exam'),
  ('project', 'Project'),
];

/// Form → AI preview with hours slider → summon.
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
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not estimate this boss. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _summon() async {
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
            hours: _hours.roundToDouble().clamp(2, 40),
            name: preview['name'] as String? ?? 'The Deadline Shade',
          );
      final boss = json['boss'];
      if (boss is! Map || boss['id'] is! String) {
        throw const ApiException(code: 'internal', message: 'Could not create this boss.');
      }
      ref.invalidate(bossesProvider);
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

  int _tierCoins(String tier) {
    return switch (tier) {
      'minion' => 100,
      'brute' => 150,
      'warlord' => 200,
      'titan' => 300,
      _ => 100,
    };
  }

  String _tierForHours(double hours) {
    if (hours < 4) return 'minion';
    if (hours < 12) return 'brute';
    if (hours < 25) return 'warlord';
    return 'titan';
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final tier = _tierForHours(_hours);
    final maxHp = (_hours * 60).round();
    final coinsEligible = _deadline != null &&
        _deadline!.difference(DateTime.now()).inHours >= 48;

    return Scaffold(
      appBar: AppBar(
        title: Text(preview == null ? 'Create boss' : 'Summon', style: AppText.h2),
        leading: BackButton(onPressed: () {
          if (preview != null) {
            setState(() => _preview = null);
          } else {
            context.go('/bosses');
          }
        }),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          if (preview == null) ...[
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
              style: AppText.body,
              onChanged: (_) => setState(() => _preview = null),
            ),
            const SizedBox(height: AppSpacing.s12),
            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              style: AppText.body,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('Type', style: AppText.h2),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              children: [
                for (final entry in _types)
                  QChip(
                    label: entry.$2,
                    selected: _type == entry.$1,
                    onTap: () => setState(() {
                      _type = entry.$1;
                      _preview = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            QButton(
              label: _deadline == null
                  ? 'Pick a deadline'
                  : 'Due ${_deadline!.day}/${_deadline!.month} ${_deadline!.hour.toString().padLeft(2, '0')}:${_deadline!.minute.toString().padLeft(2, '0')}',
              variant: QButtonVariant.secondary,
              onPressed: _busy ? null : _pickDeadline,
            ),
            const SizedBox(height: AppSpacing.s24),
            if (_error != null) ...[
              Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
              const SizedBox(height: AppSpacing.s12),
            ],
            QButton(
              label: _busy ? 'Estimating…' : 'Estimate',
              onPressed: _busy ? null : _estimate,
            ),
          ] else ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Image.asset(
                  GameAssets.boss(tier),
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(preview['name'] as String? ?? 'Boss', style: AppText.h1, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s8),
            Text(
              '${tier[0].toUpperCase()}${tier.substring(1)} · $maxHp HP · ${_tierCoins(tier)} coins',
              style: AppText.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s24),
            Text('Estimated hours: ${_hours.round()}', style: AppText.h2),
            Slider(
              value: _hours.clamp(2, 40),
              min: 2,
              max: 40,
              divisions: 38,
              label: '${_hours.round()} h',
              onChanged: _busy ? null : (value) => setState(() => _hours = value),
            ),
            Text(
              'Lower hours lowers HP and loot. Adjust if the estimate feels off.',
              style: AppText.bodySmall,
            ),
            if (!coinsEligible) ...[
              const SizedBox(height: AppSpacing.s16),
              Text(
                'No coins for this boss — the deadline is under 48 hours away.',
                style: AppText.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.s24),
            if (_error != null) ...[
              Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
              const SizedBox(height: AppSpacing.s12),
            ],
            QButton(
              label: _busy ? 'Summoning…' : 'Summon',
              onPressed: _busy ? null : _summon,
            ),
          ],
        ],
      ),
    );
  }
}
