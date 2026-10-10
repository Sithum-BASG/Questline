import 'package:freezed_annotation/freezed_annotation.dart';

part 'guild_member.freezed.dart';
part 'guild_member.g.dart';

@freezed
abstract class GuildMember with _$GuildMember {
  const factory GuildMember({
    required String guildId,
    required String userId,
    required DateTime joinedAt,
    required int questContribution,
  }) = _GuildMember;

  factory GuildMember.fromJson(Map<String, dynamic> json) =>
      _$GuildMemberFromJson(json);
}
