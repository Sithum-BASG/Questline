import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/social/friend_links.dart';

void main() {
  test('friendCodeFromUri reads questline friend links', () {
    expect(friendCodeFromUri(Uri.parse('questline://friend/AB12CD34')), 'AB12CD34');
    expect(friendCodeFromUri(Uri.parse('questline:///friend/ab12cd34')), 'AB12CD34');
    expect(friendCodeFromUri(Uri.parse('https://example.com')), isNull);
  });

  test('share text includes the plain code', () {
    final text = friendInviteShareText('AB12CD34');
    expect(text.contains('AB12CD34'), true);
    expect(text.contains('questline://friend/AB12CD34'), true);
  });
}
