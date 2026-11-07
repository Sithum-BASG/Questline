import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/api_client.dart';
import '../../core/supabase/auth_providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../core/widgets/q_chip.dart';
import '../home/providers/home_providers.dart';

const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Rest day, pause mode, and sign out. More toggles land in T080.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _busy = false;
  String? _error;
  int? _pendingRest;
  bool? _pauseActive;
  int _pauseDaysUsed = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final row = await client
          .from('player_state')
          .select('rest_weekday, pending_rest_weekday, pause_active, pause_days_used')
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _pendingRest = (row?['pending_rest_weekday'] as num?)?.toInt() ??
            (row?['rest_weekday'] as num?)?.toInt();
        _pauseActive = row?['pause_active'] == true;
        _pauseDaysUsed = (row?['pause_days_used'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {
      // Keep defaults; actions still work once online.
    }
  }

  Future<void> _saveRest(int weekday) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).setRestDay(weekday);
      if (mounted) setState(() => _pendingRest = weekday);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePause(bool active) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final until = active ? DateTime.now().toUtc().add(const Duration(days: 2)) : null;
      await ref.read(apiClientProvider).setPause(active: active, until: until);
      if (mounted) {
        setState(() {
          _pauseActive = active;
          if (active) _pauseDaysUsed = (_pauseDaysUsed + 2).clamp(0, 7);
        });
        ref.invalidate(homeSnapshotProvider);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeSnapshotProvider);
    final streak = home.asData?.value.player.streakCount;
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: AppText.h2)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          if (streak != null) ...[
            QCard(
              child: Row(
                children: [
                  Icon(Icons.local_fire_department_outlined, color: AppColors.streakEmber),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Streak', style: AppText.h2),
                        Text(
                          _pauseActive == true ? 'Paused · $streak days' : '$streak days',
                          style: AppText.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          Text('Rest day', style: AppText.h2),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Takes effect next leaderboard week. Streaks skip this weekday.',
            style: AppText.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (var i = 0; i < _weekdays.length; i++)
                QChip(
                  label: _weekdays[i],
                  selected: _pendingRest == i,
                  onTap: _busy ? null : () => _saveRest(i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          Text('Pause mode', style: AppText.h2),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Freezes streaks and boss healing. ${_pauseDaysUsed.clamp(0, 7)} / 7 days used this month.',
            style: AppText.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_pauseActive == true ? 'Pause on' : 'Pause off', style: AppText.body),
            value: _pauseActive == true,
            onChanged: _busy ? null : (value) => _togglePause(value),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.s32),
          QButton(
            label: 'Sign out',
            variant: QButtonVariant.secondary,
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
