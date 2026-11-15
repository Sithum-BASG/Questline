import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/offline/home_snapshot_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('home snapshot cache round-trips JSON', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = HomeSnapshotCache(prefs);
    await cache.save('user-a', {'greeting': 'hi', 'streak': 3});
    expect(cache.load('user-a')?['greeting'], 'hi');
    expect(cache.load('user-a')?['streak'], 3);
    await cache.clear('user-a');
    expect(cache.load('user-a'), isNull);
  });

  test('one account never sees another account\'s cached Home', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = HomeSnapshotCache(prefs);
    await cache.save('user-a', {'name': 'Amaya'});
    expect(cache.load('user-b'), isNull);
    await cache.save('user-b', {'name': 'Kavin'});
    expect(cache.load('user-a')?['name'], 'Amaya');
    expect(cache.load('user-b')?['name'], 'Kavin');
  });
}
