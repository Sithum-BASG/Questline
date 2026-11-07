import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Friend code from a deep link or scan, waiting for confirm after sign-in.
class PendingFriendCode extends Notifier<String?> {
  @override
  String? build() => null;

  void setCode(String? code) => state = code?.toUpperCase();

  void clear() => state = null;
}

final pendingFriendCodeProvider =
    NotifierProvider<PendingFriendCode, String?>(PendingFriendCode.new);
