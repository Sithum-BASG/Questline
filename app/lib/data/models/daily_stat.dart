import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_stat.freezed.dart';
part 'daily_stat.g.dart';

@freezed
abstract class DailyStat with _$DailyStat {
  const factory DailyStat({
    required String userId,
    required DateTime day,
    required int xpIntellect,
    required int xpVitality,
    required int xpCraft,
    required int xpCharisma,
    required int rawXp,
    required int focusMinutes,
    required int sessionsStarted,
    required bool metMinimum,
    required bool restDay,
    required bool paused,
  }) = _DailyStat;

  factory DailyStat.fromJson(Map<String, dynamic> json) =>
      _$DailyStatFromJson(json);
}
