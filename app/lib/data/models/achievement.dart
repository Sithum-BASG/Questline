import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

@freezed
abstract class Achievement with _$Achievement {
  const factory Achievement({
    required String userId,
    required String badgeId,
    required int progress,
    required int tier,
    required DateTime updatedAt,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
}
