/// Password strength for the sign-up meter. Minimum length matches Supabase (6).
const int kMinPasswordLength = 6;

/// Returns 0–3 filled pips for [password].
int passwordStrengthPips(String password) {
  final length = password.length;
  if (length < kMinPasswordLength) return 0;

  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
  final hasDigit = RegExp(r'\d').hasMatch(password);
  final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

  if (length >= 12 && hasLetter && hasDigit && hasSymbol) return 3;
  if (length >= 10 || (length >= kMinPasswordLength && hasLetter && hasDigit)) {
    return 2;
  }
  return 1;
}

/// Short hint shown next to the strength pips.
String passwordStrengthHint(String password) {
  switch (passwordStrengthPips(password)) {
    case 0:
      return 'Too short · at least $kMinPasswordLength characters';
    case 1:
      return 'Fair · at least $kMinPasswordLength characters';
    case 2:
      return 'Good · at least $kMinPasswordLength characters';
    default:
      return 'Strong · letters, numbers and a symbol';
  }
}
