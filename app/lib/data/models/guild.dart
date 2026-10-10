import 'package:freezed_annotation/freezed_annotation.dart';

part 'guild.freezed.dart';
part 'guild.g.dart';

@freezed
abstract class Guild with _$Guild {
  const factory Guild({
    required String id,
    required String name,
    required String emblem,
    required String leaderId,
    required String inviteCode,
    String? questWeekId,
    required int questGoal,
    required int questProgress,
    required DateTime createdAt,
  }) = _Guild;

  factory Guild.fromJson(Map<String, dynamic> json) => _$GuildFromJson(json);
}
