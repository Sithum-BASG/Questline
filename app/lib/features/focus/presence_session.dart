import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';

/// What the focus screen tells the player's presence row.
abstract class FocusPresence {
  void begin({required String stat, required DateTime startedAt});

  void heartbeat(DateTime now);

  void finish(DateTime now);
}

class PresenceSession implements FocusPresence {
  PresenceSession({
    required this.appearOffline,
    required this.onUpdate,
    this.period = const Duration(seconds: 60),
  });

  final bool appearOffline;
  final void Function(Map<String, dynamic> values) onUpdate;
  final Duration period;
  Timer? _timer;

  @override
  void begin({required String stat, required DateTime startedAt}) {
    if (appearOffline) return;
    onUpdate({
      'state': 'focusing',
      'stat': stat,
      'started_at': startedAt.toUtc().toIso8601String(),
      'last_seen': DateTime.now().toUtc().toIso8601String(),
    });
    _timer = Timer.periodic(period, (_) => heartbeat(DateTime.now()));
  }

  @override
  void heartbeat(DateTime now) {
    if (appearOffline) return;
    onUpdate({'last_seen': now.toUtc().toIso8601String()});
  }

  @override
  void finish(DateTime now) {
    _timer?.cancel();
    _timer = null;
    if (appearOffline) return;
    onUpdate({
      'state': 'idle',
      'last_seen': now.toUtc().toIso8601String(),
    });
  }
}

class SupabaseFocusPresence implements FocusPresence {
  SupabaseFocusPresence(this._client);

  final SupabaseClient _client;
  PresenceSession? _session;

  @override
  void begin({required String stat, required DateTime startedAt}) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    _client.from('user_settings').select('appear_offline').eq('user_id', userId).maybeSingle().then((row) {
      final hidden = row?['appear_offline'] == true;
      _session = PresenceSession(
        appearOffline: hidden,
        onUpdate: (values) {
          _client.from('presence').update(values).eq('user_id', userId);
        },
      );
      _session!.begin(stat: stat, startedAt: startedAt);
    });
  }

  @override
  void heartbeat(DateTime now) => _session?.heartbeat(now);

  @override
  void finish(DateTime now) => _session?.finish(now);
}

final focusPresenceProvider = Provider<FocusPresence>((ref) {
  return SupabaseFocusPresence(ref.watch(supabaseClientProvider));
});
