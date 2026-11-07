import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

TimeOfDay parseQuietTime(String raw) {
  final parts = raw.split(':');
  final hour = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0;
  final minute = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}

String formatQuietTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

String labelQuietTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Rest day, pause, notification categories, quiet hours, privacy, delete account.
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

  var _notifBosses = true;
  var _notifStreak = true;
  var _notifRaids = true;
  var _notifWeekly = true;
  var _notifLeaderboardNudge = false;
  var _quietStart = const TimeOfDay(hour: 23, minute: 0);
  var _quietEnd = const TimeOfDay(hour: 7, minute: 0);
  var _appearOffline = false;
  var _hideRadar = false;
  var _showBossNames = true;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = ref.read(authStateProvider).asData?.value.session?.user.id;
      final state = await client
          .from('player_state')
          .select('rest_weekday, pending_rest_weekday, pause_active, pause_days_used')
          .maybeSingle();
      Map<String, dynamic>? settings;
      Map<String, dynamic>? profile;
      if (userId != null) {
        settings = await client.from('user_settings').select().eq('user_id', userId).maybeSingle();
        profile = await client
            .from('profiles')
            .select('hide_radar, show_boss_names')
            .eq('id', userId)
            .maybeSingle();
      }
      if (!mounted) return;
      setState(() {
        _pendingRest = (state?['pending_rest_weekday'] as num?)?.toInt() ??
            (state?['rest_weekday'] as num?)?.toInt();
        _pauseActive = state?['pause_active'] == true;
        _pauseDaysUsed = (state?['pause_days_used'] as num?)?.toInt() ?? 0;
        if (settings != null) {
          _notifBosses = settings['notif_bosses'] == true;
          _notifStreak = settings['notif_streak'] == true;
          _notifRaids = settings['notif_raids'] == true;
          _notifWeekly = settings['notif_weekly'] == true;
          _notifLeaderboardNudge = settings['notif_leaderboard_nudge'] == true;
          _quietStart = parseQuietTime(settings['quiet_start'] as String? ?? '23:00:00');
          _quietEnd = parseQuietTime(settings['quiet_end'] as String? ?? '07:00:00');
          _appearOffline = settings['appear_offline'] == true;
        }
        if (profile != null) {
          _hideRadar = profile['hide_radar'] == true;
          _showBossNames = profile['show_boss_names'] != false;
        }
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _patchSettings(Map<String, dynamic> patch) async {
    final userId = ref.read(authStateProvider).asData?.value.session?.user.id;
    if (userId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(supabaseClientProvider)
          .from('user_settings')
          .update(patch)
          .eq('user_id', userId);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save settings.');
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _patchProfile(Map<String, dynamic> patch) async {
    final userId = ref.read(authStateProvider).asData?.value.session?.user.id;
    if (userId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(supabaseClientProvider).from('profiles').update(patch).eq('id', userId);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save privacy settings.');
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
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

  Future<void> _pickQuiet({required bool start}) async {
    final current = start ? _quietStart : _quietEnd;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _quietStart = picked;
      } else {
        _quietEnd = picked;
      }
    });
    await _patchSettings({
      if (start) 'quiet_start': formatQuietTime(picked) else 'quiet_end': formatQuietTime(picked),
    });
  }

  Future<void> _confirmDelete() async {
    final step1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete account?', style: AppText.h2),
        content: Text(
          'This permanently removes your character, progress and friends. You cannot undo it.',
          style: AppText.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    if (step1 != true || !mounted) return;

    final step2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?', style: AppText.h2),
        content: Text(
          'Your account and all Questline data will be deleted now.',
          style: AppText.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep account')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete forever', style: AppText.body.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (step2 != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account was deleted.')),
      );
      context.go('/welcome');
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
          Text('Notifications', style: AppText.h2),
          const SizedBox(height: AppSpacing.s8),
          _NotifTile(
            title: 'Bosses',
            value: _notifBosses,
            enabled: _loaded && !_busy,
            onChanged: (value) {
              setState(() => _notifBosses = value);
              _patchSettings({'notif_bosses': value});
            },
          ),
          _NotifTile(
            title: 'Streak reminders',
            value: _notifStreak,
            enabled: _loaded && !_busy,
            onChanged: (value) {
              setState(() => _notifStreak = value);
              _patchSettings({'notif_streak': value});
            },
          ),
          _NotifTile(
            title: 'Raids',
            value: _notifRaids,
            enabled: _loaded && !_busy,
            onChanged: (value) {
              setState(() => _notifRaids = value);
              _patchSettings({'notif_raids': value});
            },
          ),
          _NotifTile(
            title: 'Weekly results',
            value: _notifWeekly,
            enabled: _loaded && !_busy,
            onChanged: (value) {
              setState(() => _notifWeekly = value);
              _patchSettings({'notif_weekly': value});
            },
          ),
          _NotifTile(
            title: 'Leaderboard nudge',
            value: _notifLeaderboardNudge,
            enabled: _loaded && !_busy,
            onChanged: (value) {
              setState(() => _notifLeaderboardNudge = value);
              _patchSettings({'notif_leaderboard_nudge': value});
            },
          ),
          const SizedBox(height: AppSpacing.s24),
          Text('Quiet hours', style: AppText.h2),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Local reminders stay silent in this window.',
            style: AppText.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy || !_loaded ? null : () => _pickQuiet(start: true),
                  child: Text('From ${labelQuietTime(_quietStart)}', style: AppText.body),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy || !_loaded ? null : () => _pickQuiet(start: false),
                  child: Text('Until ${labelQuietTime(_quietEnd)}', style: AppText.body),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          Text('Privacy', style: AppText.h2),
          const SizedBox(height: AppSpacing.s8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Appear offline', style: AppText.body),
            subtitle: Text('Hides the focusing status from friends.', style: AppText.bodySmall),
            value: _appearOffline,
            onChanged: _busy || !_loaded
                ? null
                : (value) {
                    setState(() => _appearOffline = value);
                    _patchSettings({'appear_offline': value});
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Hide stat radar', style: AppText.body),
            subtitle: Text('Friends will not see your radar chart.', style: AppText.bodySmall),
            value: _hideRadar,
            onChanged: _busy || !_loaded
                ? null
                : (value) {
                    setState(() => _hideRadar = value);
                    _patchProfile({'hide_radar': value});
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Show boss names in feed', style: AppText.body),
            subtitle: Text('Off keeps boss titles private in activity.', style: AppText.bodySmall),
            value: _showBossNames,
            onChanged: _busy || !_loaded
                ? null
                : (value) {
                    setState(() => _showBossNames = value);
                    _patchProfile({'show_boss_names': value});
                  },
          ),
          const SizedBox(height: AppSpacing.s24),
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
            onPressed: _busy ? null : () => ref.read(authRepositoryProvider).signOut(),
          ),
          const SizedBox(height: AppSpacing.s12),
          QButton(
            label: 'Delete account',
            variant: QButtonVariant.destructive,
            onPressed: _busy ? null : _confirmDelete,
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppText.body),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}
