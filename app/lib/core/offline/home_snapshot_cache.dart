import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _homeSnapshotKey = 'home_snapshot_v1';

/// Last successful Home payload, for the offline pill.
class HomeSnapshotCache {
  HomeSnapshotCache(this._prefs);

  final SharedPreferences _prefs;

  Future<void> save(Map<String, dynamic> json) async {
    await _prefs.setString(_homeSnapshotKey, jsonEncode(json));
  }

  Map<String, dynamic>? load() {
    final raw = _prefs.getString(_homeSnapshotKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> clear() => _prefs.remove(_homeSnapshotKey);
}
