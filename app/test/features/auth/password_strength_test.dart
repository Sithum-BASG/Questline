import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/auth/password_strength.dart';

void main() {
  test('strength pips follow length and character mix rules', () {
    expect(passwordStrengthPips(''), 0);
    expect(passwordStrengthPips('abc'), 0);
    expect(passwordStrengthPips('abcdef'), 1);
    expect(passwordStrengthPips('abcdefghij'), 2);
    expect(passwordStrengthPips('abcde1'), 2);
    expect(passwordStrengthPips('abcdefghijk1!'), 3);
  });

  test('strength hints mention the real minimum length', () {
    expect(passwordStrengthHint('ab'), contains('$kMinPasswordLength'));
    expect(passwordStrengthHint('abcdef'), contains('Fair'));
    expect(passwordStrengthHint('abcdefghij'), contains('Good'));
    expect(passwordStrengthHint('abcdefghijk1!'), contains('Strong'));
  });
}
