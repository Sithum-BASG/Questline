import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/offline/home_snapshot_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('home snapshot cache round-trips JSON', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = HomeSnapshotCache(prefs);
    await cache.save({'greeting': 'hi', 'streak': 3});
    expect(cache.load()?['greeting'], 'hi');
    expect(cache.load()?['streak'], 3);
    await cache.clear();
    expect(cache.load(), isNull);
  });
}
