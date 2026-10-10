import 'package:freezed_annotation/freezed_annotation.dart';

part 'presence.freezed.dart';
part 'presence.g.dart';

@freezed
abstract class Presence with _$Presence {
  const factory Presence({
    required String userId,
    required String state,
    String? stat,
    DateTime? startedAt,
    String? raidId,
    required DateTime lastSeen,
  }) = _Presence;

  factory Presence.fromJson(Map<String, dynamic> json) =>
      _$PresenceFromJson(json);
}
