import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/raids/raid_links.dart';

void main() {
  test('raidCodeFromUri reads questline join links', () {
    expect(raidCodeFromUri(Uri.parse('questline://join/ABCD1234')), 'ABCD1234');
    expect(raidCodeFromUri(Uri.parse('questline:///join/abcd1234')), 'ABCD1234');
    expect(raidCodeFromUri(Uri.parse('questline://friend/ABCD1234')), null);
  });

  test('share text includes the plain code', () {
    final text = raidInviteShareText('ABCD1234');
    expect(text.contains('ABCD1234'), true);
    expect(text.contains('questline://join/ABCD1234'), true);
  });
}
