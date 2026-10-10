import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
abstract class UserSettings with _$UserSettings {
  const factory UserSettings({
    required String userId,
    required bool notifBosses,
    required bool notifStreak,
    required bool notifRaids,
    required bool notifWeekly,
    required bool notifLeaderboardNudge,
    required String quietStart,
    required String quietEnd,
    required bool appearOffline,
    String? studyContext,
    required bool demoMode,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
