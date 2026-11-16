import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/auth/auth_links.dart';

void main() {
  test('detects questline auth-callback hosts and paths', () {
    expect(isAuthCallbackUri(Uri.parse('questline://auth-callback')), isTrue);
    expect(isAuthCallbackUri(Uri.parse('questline://auth-callback?code=abc')), isTrue);
    expect(isAuthCallbackUri(Uri.parse('questline:///auth-callback')), isTrue);
    expect(isAuthCallbackUri(Uri.parse('questline://friend/AB12CD34')), isFalse);
    expect(isAuthCallbackUri(Uri.parse('questline://join/ABCD1234')), isFalse);
  });
}
