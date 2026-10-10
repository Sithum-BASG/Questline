import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_score.freezed.dart';
part 'weekly_score.g.dart';

@freezed
abstract class WeeklyScore with _$WeeklyScore {
  const factory WeeklyScore({
    required String weekId,
    required String userId,
    required int rawXp,
    required DateTime updatedAt,
  }) = _WeeklyScore;

  factory WeeklyScore.fromJson(Map<String, dynamic> json) =>
      _$WeeklyScoreFromJson(json);
}
