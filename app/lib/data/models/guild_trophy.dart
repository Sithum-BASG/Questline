import 'package:freezed_annotation/freezed_annotation.dart';

part 'guild_trophy.freezed.dart';
part 'guild_trophy.g.dart';

@freezed
abstract class GuildTrophy with _$GuildTrophy {
  const factory GuildTrophy({
    required String guildId,
    required String raidId,
    String? name,
    DateTime? wonAt,
  }) = _GuildTrophy;

  factory GuildTrophy.fromJson(Map<String, dynamic> json) =>
      _$GuildTrophyFromJson(json);
}
