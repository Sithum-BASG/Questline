import 'package:freezed_annotation/freezed_annotation.dart';

part 'level_reward.freezed.dart';
part 'level_reward.g.dart';

@freezed
abstract class LevelReward with _$LevelReward {
  const factory LevelReward({
    required int level,
    required List<Map<String, dynamic>> rewards,
  }) = _LevelReward;

  factory LevelReward.fromJson(Map<String, dynamic> json) =>
      _$LevelRewardFromJson(json);
}
