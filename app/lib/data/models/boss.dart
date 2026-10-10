import 'package:freezed_annotation/freezed_annotation.dart';

part 'boss.freezed.dart';
part 'boss.g.dart';

@freezed
abstract class Boss with _$Boss {
  const factory Boss({
    required String id,
    required String userId,
    required String name,
    required String title,
    required String type,
    required String tier,
    required double hours,
    required int maxHp,
    required int damage,
    required DateTime deadline,
    required DateTime createdAt,
    required String status,
    DateTime? lastWorkDay,
    required bool coinsEligible,
    Map<String, dynamic>? loot,
    required bool resultSeen,
  }) = _Boss;

  factory Boss.fromJson(Map<String, dynamic> json) => _$BossFromJson(json);
}
