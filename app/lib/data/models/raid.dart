import 'package:freezed_annotation/freezed_annotation.dart';

part 'raid.freezed.dart';
part 'raid.g.dart';

@freezed
abstract class Raid with _$Raid {
  const factory Raid({
    required String id,
    required String source,
    String? guildId,
    required String name,
    required String title,
    required String type,
    required String tier,
    required int perPersonMinutes,
    required int participants,
    required int maxHp,
    required int damage,
    required DateTime deadline,
    required String status,
    String? createdBy,
    String? inviteCode,
    required bool coinsEligible,
    required DateTime createdAt,
  }) = _Raid;

  factory Raid.fromJson(Map<String, dynamic> json) => _$RaidFromJson(json);
}
