import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_summary.freezed.dart';
part 'friend_summary.g.dart';

@freezed
abstract class FriendSummary with _$FriendSummary {
  const factory FriendSummary({
    required String userId,
    required List<dynamic> equippedGear,
    required int weeklyRawXp,
    Map<String, dynamic>? radar30,
    Map<String, dynamic>? radar7,
    required DateTime updatedAt,
  }) = _FriendSummary;

  factory FriendSummary.fromJson(Map<String, dynamic> json) =>
      _$FriendSummaryFromJson(json);
}
