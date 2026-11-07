import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set after the first session so reward → free chest → Home (Add friends).
final pendingOnboardingChestProvider =
    NotifierProvider<PendingOnboardingChest, bool>(PendingOnboardingChest.new);

class PendingOnboardingChest extends Notifier<bool> {
  @override
  bool build() => false;

  void setPending(bool value) => state = value;
}
