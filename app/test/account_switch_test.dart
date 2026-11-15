import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/supabase/supabase_providers.dart';

/// Stands in for any screen data provider (Home, Hero, quests...).
var _loads = 0;
final _screenDataProvider = FutureProvider<int>((ref) async {
  watchAccount(ref);
  return ++_loads;
});

void main() {
  test('switching accounts reloads user data; a token refresh does not', () async {
    final users = StreamController<String?>.broadcast();
    final container = ProviderContainer(overrides: [
      signedInUserIdProvider.overrideWith((ref) => users.stream.distinct()),
    ]);
    addTearDown(container.dispose);
    addTearDown(users.close);
    _loads = 0;
    container.listen(_screenDataProvider, (_, _) {});

    Future<int> settle() async {
      await Future<void>.delayed(Duration.zero);
      return container.read(_screenDataProvider.future);
    }

    expect(await settle(), 1);

    users.add('amaya');
    expect(await settle(), 2, reason: 'signing in loads that account');

    users.add('amaya');
    expect(await settle(), 2, reason: 'a token refresh keeps the same data');

    users.add('kavin');
    expect(await settle(), 3, reason: 'another account reloads');

    users.add(null);
    expect(await settle(), 4, reason: 'signing out drops the data');
  });
}
