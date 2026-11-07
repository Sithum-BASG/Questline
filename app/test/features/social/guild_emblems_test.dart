import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/social/guild_emblems.dart';

void main() {
  test('guild emblems are eight preset crest ids', () {
    expect(guildEmblemIds.length, 8);
    expect(guildEmblemIds.first, 'crest_1');
    expect(guildEmblemLabel('crest_3'), 'Crest 3');
  });
}
