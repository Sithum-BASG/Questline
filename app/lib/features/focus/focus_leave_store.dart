import 'package:shared_preferences/shared_preferences.dart';

const _sessionKey = 'focus_leave_session_id';
const _leftAtKey = 'focus_leave_at';

/// Persists an open focus leave across process death (low-end LMK / kill).
class FocusLeaveStore {
  const FocusLeaveStore();

  Future<void> save({required String sessionId, required DateTime leftAt}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, sessionId);
    await prefs.setString(_leftAtKey, leftAt.toUtc().toIso8601String());
  }

  Future<DateTime?> loadLeftAt(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_sessionKey) != sessionId) return null;
    final raw = prefs.getString(_leftAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_leftAtKey);
  }
}
