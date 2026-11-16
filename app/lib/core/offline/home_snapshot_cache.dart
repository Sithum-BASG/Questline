import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _homeSnapshotKey = 'home_snapshot_v2';

/// Last successful Home payload, for the offline pill.
class HomeSnapshotCache {
  HomeSnapshotCache(this._prefs);

  final SharedPreferences _prefs;

  /// One snapshot per account, so another account's Home never shows offline.
  String _key(String userId) => '$_homeSnapshotKey:$userId';

  Future<void> save(String userId, Map<String, dynamic> json) async {
    await _prefs.setString(_key(userId), jsonEncode(json));
  }

  Map<String, dynamic>? load(String userId) {
    final raw = _prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> clear(String userId) => _prefs.remove(_key(userId));
}
