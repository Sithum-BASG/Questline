import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/portrait_frame.dart';
import '../../core/widgets/q_card.dart';
import 'providers/profile_providers.dart';

class WardrobeItem {
  const WardrobeItem({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final String type;
}

class WardrobeData {
  const WardrobeData({
    required this.skinId,
    required this.backgroundId,
    required this.frameId,
    required this.body,
    required this.owned,
  });

  final String skinId;
  final String backgroundId;
  final String frameId;
  final BodyType body;
  final List<WardrobeItem> owned;
}

final wardrobeProvider = FutureProvider<WardrobeData>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final profile = (await ref.watch(profileViewProvider.future)).profile;
  final inv = await client.from('inventory').select('catalog_id');
  final ids = [for (final row in inv) row['catalog_id'] as String];
  final cosmeticIds = ids.where((id) => id.startsWith('skin_') || id.startsWith('bg_') || id.startsWith('frame_')).toList();
  final items = <WardrobeItem>[];
  if (cosmeticIds.isNotEmpty) {
    final rows = await client.from('catalog_items').select('id, name, type').inFilter('id', cosmeticIds);
    for (final row in rows) {
      items.add(WardrobeItem(
        id: row['id'] as String,
        name: row['name'] as String? ?? row['id'] as String,
        type: row['type'] as String? ?? 'skin',
      ));
    }
  }
  return WardrobeData(
    skinId: profile.equippedSkinId,
    backgroundId: profile.equippedBackgroundId,
    frameId: profile.equippedFrameId,
    body: profile.bodyType == 'b' ? BodyType.b : BodyType.a,
    owned: items,
  );
});

String _short(String id, String prefix) => id.startsWith(prefix) ? id.substring(prefix.length) : id;

/// Client updates equipped cosmetics; the ownership trigger rejects unowned ids.
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String? _error;

  Future<void> _equip(WardrobeItem item) async {
    setState(() => _error = null);
    final column = switch (item.type) {
      'skin' => 'equipped_skin_id',
      'background' => 'equipped_background_id',
      'frame' => 'equipped_frame_id',
      _ => null,
    };
    if (column == null) return;
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('profiles').update({column: item.id});
      ref.invalidate(wardrobeProvider);
      ref.invalidate(profileViewProvider);
    } catch (_) {
      if (mounted) setState(() => _error = 'You need to own that item first.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wardrobeProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Wardrobe', style: AppText.h2)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          title: 'Could not load wardrobe',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(wardrobeProvider),
        ),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s16,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              Center(
                child: PortraitFrame(
                  skinId: _short(data.skinId, 'skin_'),
                  backgroundId: _short(data.backgroundId, 'bg_'),
                  frameId: _short(data.frameId, 'frame_'),
                  body: data.body,
                  size: PortraitFrameSize.profile,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.s24),
              for (final type in const ['skin', 'background', 'frame']) ...[
                Text(type[0].toUpperCase() + type.substring(1), style: AppText.h2),
                const SizedBox(height: AppSpacing.s8),
                ...data.owned.where((item) => item.type == type).map((item) {
                  final equipped = item.id == data.skinId || item.id == data.backgroundId || item.id == data.frameId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: QCard(
                      onTap: equipped ? null : () => _equip(item),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.name, style: AppText.body)),
                          if (equipped)
                            Text('Equipped', style: AppText.caption.copyWith(color: AppColors.tealDeep))
                          else
                            Text('Equip', style: AppText.caption.copyWith(color: AppColors.inkMuted)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.s16),
              ],
            ],
          );
        },
      ),
    );
  }
}
