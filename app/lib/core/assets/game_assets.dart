// Questline art pack: asset paths and placement constants.
// Copy this file into lib/ (for example lib/core/game_assets.dart).
// Every path matches a file under assets/images/ in this pack.

import 'dart:ui' show Rect, Size;

enum BodyType { a, b }

class GameAssets {
  GameAssets._();

  static const String _root = 'assets/images';

  // ---------------------------------------------------------------------------
  // Paths
  // ---------------------------------------------------------------------------

  /// Character skin, 1024 x 1536 transparent. [id] is a value of [skinIds].
  static String skin(String id, BodyType body) =>
      '$_root/skins/skin_${id}_${body.name}.webp';

  /// Stage background, 1024 x 1536 opaque. Same canvas as skins (layer 1:1).
  static String background(String id) => '$_root/backgrounds/bg_$id.webp';

  /// Profile frame, 512 x 512 transparent (window is see-through).
  static String frame(String id) => '$_root/frames/frame_$id.webp';

  /// Deadline boss, 1024 x 1024 transparent. [tier] is a value of [bossTiers].
  static String boss(String tier) => '$_root/bosses/boss_$tier.webp';

  /// Gear item, 1024 x 1024 transparent. [id] includes the slot,
  /// for example 'weapon_apprentice_wand'.
  static String gear(String id) => '$_root/gear/gear_$id.webp';

  /// Achievement badge (emblem already inside its tier frame), 512 x 512.
  /// [tier] is 1, 2 or 3.
  static String badge(String id, int tier) =>
      '$_root/badges/badge_${id}_$tier.webp';

  /// Empty badge tier frame (for locked badges), 512 x 512. [tier] is 1-3.
  static String badgeFrame(int tier) => '$_root/badges/badge_frame_$tier.webp';

  /// Item and currency icons. [id] is a value of [iconIds].
  static String icon(String id) => '$_root/icons/icon_$id.webp';

  /// Onboarding story image (1-7), 1024 x 1024. Cards 1, 5, 6 and 7 show the
  /// hero and follow the chosen body type; cards 2, 3 and 4 are shared.
  static String story(int card, BodyType body) =>
      _storyHeroCards.contains(card)
          ? '$_root/story/story_${card}_${body.name}.webp'
          : '$_root/story/story_$card.webp';
  static const Set<int> _storyHeroCards = {1, 5, 6, 7};

  /// Transparent logo symbol for splash and welcome screens, 512 x 512.
  static const String logoMark = '$_root/brand/logo_mark.webp';

  // ---------------------------------------------------------------------------
  // Ids
  // ---------------------------------------------------------------------------

  static const List<String> skinIds = [
    'starter', // default
    'coder', // L4 Common
    'alchemist', // L14 Rare
    'sigil_runner', // L24 Rare
    'starweaver', // L36 Epic
    'awakened', // L50 Epic
    'sunscholar', // Legendary chest
    'elfwarden', // Legendary chest
    'chronomancer', // Mythic chest (set)
  ];

  static const List<String> backgroundIds = [
    'starter', // default
    'quad', // L6 Common
    'study_room', // L8 Common
    'chem_lab', // L18 Rare
    'running_track', // L22 Rare
    'observatory', // L28 Epic
    'lecture_hall', // L34 Epic
    'lake_bridge', // L44 Epic
    'grand_library', // L48 Epic
    'cafe', // Rare chest
    'greenhouse', // Rare chest
    'cloister', // Epic chest
    'archive_vault', // Epic chest
    'sky_library', // Legendary chest
    'elderwood', // Legendary chest
    'chronosphere', // Mythic chest (set)
  ];

  static const List<String> frameIds = [
    'apprentice', // default, Common
    'margin_notes', // L2 Common
    'bookworm', // L7 Common
    'silver_quill', // L12 Rare
    'alchemist_glass', // Rare chest
    'runestone', // Rare chest
    'constellation', // L26 Epic
    'spellwire', // L38 Epic
    'amethyst_bloom', // Epic chest
    'lunar_moth', // Epic chest
    'wyrmscale', // Epic chest
    'sunscholar', // Legendary chest
    'elfwarden', // Legendary chest
    'chronomancer', // Mythic chest (set)
    'unbroken', // 60-day streak
  ];

  static const List<String> bossTiers = ['minion', 'brute', 'warlord', 'titan'];

  static const List<String> gearIds = [
    'weapon_apprentice_wand', // L5 Common
    'armour_patched_jacket', // L10 Common
    'accessory_focus_lens', // L15 Rare
    'weapon_ink_nib_dagger', // L20 Rare
    'armour_scholar_coat', // L25 Rare
    'accessory_starlit_headphones', // L30 Epic
    'weapon_arcane_grimoire', // L35 Epic
    'armour_moonweave_cloak', // L40 Epic
    'accessory_deep_focus', // L45 Legendary
    'weapon_deadline_breaker', // L50 Legendary
  ];

  static const List<String> badgeIds = [
    'deep_worker',
    'boss_hunter',
    'team_player',
    'unbroken',
    'balanced',
    'early_bird',
    'steady_pace',
    'punctual',
  ];

  static const List<String> iconIds = [
    'chest', // closed chest, small (lists, inventory)
    'chest_large', // closed chest, 1024 px (Chest screen)
    'chest_open', // open chest, small
    'chest_open_large', // open chest, 1024 px (reveal)
    'coin',
    'pouch_small',
    'pouch_medium',
    'pouch_large',
    'pouch_jackpot',
    'streak_shield',
    'focus_potion',
    'reschedule_scroll',
  ];

  // ---------------------------------------------------------------------------
  // Placement
  // ---------------------------------------------------------------------------

  /// Skins and backgrounds share this canvas.
  static const Size stageCanvas = Size(1024, 1536);

  /// Every skin's feet sit on this line, centred horizontally at x = 512.
  static const double skinFeetY = 1490;

  /// Bosses: 1024 x 1024 canvas, feet on this line.
  static const double bossFeetY = 984;

  /// Profile portrait: a 560 x 560 square cut from the top of the stage
  /// canvas (skin over background, same rect from both layers).
  /// This map holds the left edge of that square per skin id + body type.
  static const Map<String, double> portraitCropLeft = {
    'starter_a': 207, 'starter_b': 168,
    'coder_a': 194, 'coder_b': 145,
    'alchemist_a': 181, 'alchemist_b': 167,
    'sigil_runner_a': 208, 'sigil_runner_b': 144,
    'starweaver_a': 183, 'starweaver_b': 132,
    'awakened_a': 217, 'awakened_b': 169,
    'sunscholar_a': 160, 'sunscholar_b': 134,
    'elfwarden_a': 227, 'elfwarden_b': 188,
    'chronomancer_a': 265, 'chronomancer_b': 156,
  };

  /// Source rect (in stage-canvas pixels) for the profile portrait.
  static Rect portraitCrop(String skinId, BodyType body) {
    final left = portraitCropLeft['${skinId}_${body.name}'] ?? 232;
    return Rect.fromLTWH(left, 0, 560, 560);
  }

  /// Profile frame layout, as fractions of the frame's square size.
  /// Draw the portrait first as a rounded square at this rect, then the frame
  /// image on top at full size. Identical for every frame.
  static const double framePortraitInset = 182 / 1024; // 0.1777
  static const double framePortraitSize = 660 / 1024; // 0.6445
  static const double framePortraitRadius = 84 / 1024; // 0.0820

  static Rect framePortraitRect(double frameSize) => Rect.fromLTWH(
        frameSize * framePortraitInset,
        frameSize * framePortraitInset,
        frameSize * framePortraitSize,
        frameSize * framePortraitSize,
      );

  /// Onboarding story: the image fades into Paper starting at this fraction
  /// of its height and is fully Paper at the bottom edge.
  static const double storyFadeStart = 0.58;

}
