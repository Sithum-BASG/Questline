import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set while the user is finishing a password-reset deep link.
final passwordRecoveryProvider = NotifierProvider<PasswordRecoveryNotifier, bool>(
  PasswordRecoveryNotifier.new,
);

class PasswordRecoveryNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void begin() => state = true;

  void clear() => state = false;
}
