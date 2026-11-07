import '../../data/models/boss.dart';
import '../../data/models/player_state.dart';
import '../../data/models/profile.dart';
import '../../data/models/task.dart';

/// Everything Home needs in one place (and what we cache offline).
class HomeSnapshot {
  const HomeSnapshot({
    required this.profile,
    required this.player,
    required this.tasks,
    this.closestBoss,
    this.weeklyRank,
    this.unreadInbox = 0,
    this.nextRewardLabel,
    this.showAddFriends = false,
    this.offline = false,
  });

  final Profile profile;
  final PlayerState player;
  final List<Task> tasks;
  final Boss? closestBoss;
  final int? weeklyRank;
  final int unreadInbox;
  final String? nextRewardLabel;
  final bool showAddFriends;
  final bool offline;

  HomeSnapshot copyWith({bool? offline}) {
    return HomeSnapshot(
      profile: profile,
      player: player,
      tasks: tasks,
      closestBoss: closestBoss,
      weeklyRank: weeklyRank,
      unreadInbox: unreadInbox,
      nextRewardLabel: nextRewardLabel,
      showAddFriends: showAddFriends,
      offline: offline ?? this.offline,
    );
  }

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'player': player.toJson(),
        'tasks': [for (final task in tasks) task.toJson()],
        'closestBoss': closestBoss?.toJson(),
        'weeklyRank': weeklyRank,
        'unreadInbox': unreadInbox,
        'nextRewardLabel': nextRewardLabel,
        'showAddFriends': showAddFriends,
      };

  factory HomeSnapshot.fromJson(Map<String, dynamic> json, {bool offline = false}) {
    final taskRows = json['tasks'];
    return HomeSnapshot(
      profile: Profile.fromJson(Map<String, dynamic>.from(json['profile'] as Map)),
      player: PlayerState.fromJson(Map<String, dynamic>.from(json['player'] as Map)),
      tasks: [
        if (taskRows is List)
          for (final row in taskRows)
            if (row is Map) Task.fromJson(Map<String, dynamic>.from(row)),
      ],
      closestBoss: json['closestBoss'] is Map
          ? Boss.fromJson(Map<String, dynamic>.from(json['closestBoss'] as Map))
          : null,
      weeklyRank: json['weeklyRank'] as int?,
      unreadInbox: (json['unreadInbox'] as num?)?.toInt() ?? 0,
      nextRewardLabel: json['nextRewardLabel'] as String?,
      showAddFriends: json['showAddFriends'] == true,
      offline: offline,
    );
  }
}
