import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/social/friend_links.dart';
import 'package:questline/features/social/friend_qr_sheet.dart';

void main() {
  testWidgets('your friend QR opens and shows the code', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => showFriendQrSheet(context, 'AB12CD34'), child: const Text('open')),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('AB12CD34'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
  });

  test('scanned text resolves to a friend code', () {
    expect(friendCodeFromScan('questline://friend/ab12cd34'), 'AB12CD34');
    expect(friendCodeFromScan('questline:///friend/AB12CD34/'), 'AB12CD34');
    expect(friendCodeFromScan('  AB12CD34 '), 'AB12CD34');
    expect(friendCodeFromScan('AB12-CD34'), 'AB12CD34');
    expect(friendCodeFromScan('questline://raid/AB12CD34'), isNull);
    expect(friendCodeFromScan('https://example.com'), isNull);
    expect(friendCodeFromScan('questline://friend/short'), isNull);
  });
}
