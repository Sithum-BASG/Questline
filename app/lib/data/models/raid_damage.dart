import 'package:freezed_annotation/freezed_annotation.dart';

part 'raid_damage.freezed.dart';
part 'raid_damage.g.dart';

@freezed
abstract class RaidDamage with _$RaidDamage {
  const factory RaidDamage({
    required String raidId,
    required String userId,
    required int damage,
  }) = _RaidDamage;

  factory RaidDamage.fromJson(Map<String, dynamic> json) =>
      _$RaidDamageFromJson(json);
}
