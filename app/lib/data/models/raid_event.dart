import 'package:freezed_annotation/freezed_annotation.dart';

part 'raid_event.freezed.dart';
part 'raid_event.g.dart';

@freezed
abstract class RaidEvent with _$RaidEvent {
  const factory RaidEvent({
    required int id,
    required String raidId,
    required String userId,
    required String displayName,
    required int amount,
    required DateTime at,
  }) = _RaidEvent;

  factory RaidEvent.fromJson(Map<String, dynamic> json) =>
      _$RaidEventFromJson(json);
}
