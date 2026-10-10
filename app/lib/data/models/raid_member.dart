import 'package:freezed_annotation/freezed_annotation.dart';

part 'raid_member.freezed.dart';
part 'raid_member.g.dart';

@freezed
abstract class RaidMember with _$RaidMember {
  const factory RaidMember({
    required String raidId,
    required String userId,
    required String displayName,
    String? skinId,
    String? frameId,
    String? bodyType,
    String? titleId,
    required DateTime joinedAt,
    required bool leftRaid,
    required bool metFairShare,
    required bool isMvp,
  }) = _RaidMember;

  factory RaidMember.fromJson(Map<String, dynamic> json) =>
      _$RaidMemberFromJson(json);
}
