import 'package:flutter_test/flutter_test.dart';
import 'package:questline/data/models/catalog_item.dart';
import 'package:questline/data/models/level_reward.dart';
import 'package:questline/data/models/player_state.dart';
import 'package:questline/data/models/profile.dart';
import 'package:questline/data/models/user_settings.dart';

void main() {
  test('player models round-trip snake_case json', () {
    final profile = Profile.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'username': 'ada_01',
      'friend_code': 'ABCDEFGH',
      'display_name': 'Ada',
      'body_type': 'a',
      'level': 1,
      'title_id': null,
      'equipped_skin_id': 'skin_starter',
      'equipped_background_id': 'bg_starter',
      'equipped_frame_id': 'frame_apprentice',
      'pinned_badges': <String>[],
      'guild_id': null,
      'hide_radar': false,
      'show_boss_names': false,
      'created_at': '2026-10-10T04:00:00.000Z',
    });
    expect(profile.toJson()['display_name'], 'Ada');
    expect(profile.toJson()['equipped_skin_id'], 'skin_starter');

    final state = PlayerState.fromJson({
      'user_id': profile.id,
      'coins': 0,
      'xp_total': 20,
      'weekly_raw_xp': 0,
      'week_id': '2026-W41',
      'streak_count': 0,
      'streak_last_counted_day': null,
      'streak_best': 0,
      'shields': 0,
      'last_shield_day': null,
      'potions': 0,
      'scrolls': 0,
      'free_chests': 0,
      'active_potion': false,
      'comeback_armed': false,
      'inactive_days': 0,
      'chests_since_legendary': 0,
      'boss_coins_this_week': 0,
      'ai_calls_today': 0,
      'focus_minutes_today': 0,
      'onboarding_step': 'character',
      'onboarding_bonus': {
        'character': true,
        'first_task': false,
        'first_session': false,
      },
      'owned_titles': <String>[],
      'counters': {'focus_minutes': 0},
      'milestones_paid': <int>[],
      'timezone': 'Asia/Colombo',
      'last_active_day': null,
      'next_rollover_at': '2026-10-11T04:00:00.000Z',
      'rest_weekday': null,
      'pending_rest_weekday': null,
      'pause_active': false,
      'pause_until': null,
      'pause_days_used': 0,
      'pause_month': null,
    });
    expect(state.toJson()['week_id'], '2026-W41');
    expect(state.xpTotal, 20);

    final settings = UserSettings.fromJson({
      'user_id': profile.id,
      'notif_bosses': true,
      'notif_streak': true,
      'notif_raids': true,
      'notif_weekly': true,
      'notif_leaderboard_nudge': false,
      'quiet_start': '23:00:00',
      'quiet_end': '07:00:00',
      'appear_offline': false,
      'study_context': null,
      'demo_mode': false,
    });
    expect(settings.toJson()['quiet_start'], '23:00:00');

    final item = CatalogItem.fromJson({
      'id': 'skin_starter',
      'type': 'skin',
      'name': 'Starter',
      'rarity': null,
      'source': 'starter',
      'level': null,
      'slot': null,
      'boost': null,
      'passive': null,
      'set_id': null,
      'assets': {'a': 'skin_starter_a.png'},
    });
    expect(item.toJson()['set_id'], isNull);

    final reward = LevelReward.fromJson({
      'level': 2,
      'rewards': [
        {'type': 'item', 'id': 'frame_margin_notes'},
      ],
    });
    expect(reward.toJson()['level'], 2);
  });
}
