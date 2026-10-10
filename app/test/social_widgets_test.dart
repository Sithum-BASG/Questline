import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/assets/game_assets.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/judgement_card.dart';
import 'package:questline/core/widgets/leaderboard_row.dart';
import 'package:questline/core/widgets/member_card.dart';

void main() {
  testWidgets('judgement card shows the estimate and xp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: JudgementCard(
            stat: 'intellect',
            difficulty: 4,
            minutes: 90,
            xpPreview: 86,
            reason: 'A long writing task.',
          ),
        ),
      ),
    );
    expect(find.text('~90 min'), findsOneWidget);
    expect(find.text('86 XP'), findsOneWidget);
  });

  testWidgets('leaderboard and member rows show names', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              LeaderboardRow(
                rank: 1,
                name: 'Asha',
                title: 'Adept',
                xp: 500,
                skinId: 'starter',
                backgroundId: 'starter',
                body: BodyType.a,
                isYou: true,
              ),
              MemberCard(
                name: 'Nimal',
                title: 'Freshly awakened',
                skinId: 'starter',
                backgroundId: 'starter',
                body: BodyType.b,
                focusing: true,
                pulledWeight: true,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Nimal'), findsOneWidget);
  });
}
