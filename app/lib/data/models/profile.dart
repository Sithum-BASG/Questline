import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String username,
    required String friendCode,
    required String displayName,
    required String bodyType,
    required int level,
    String? titleId,
    required String equippedSkinId,
    required String equippedBackgroundId,
    required String equippedFrameId,
    required List<String> pinnedBadges,
    String? guildId,
    required bool hideRadar,
    required bool showBossNames,
    required DateTime createdAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
