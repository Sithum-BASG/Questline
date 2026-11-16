import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Supabase rejects an UPDATE or DELETE without a filter (400), and the app's
/// unit tests stub the data layer, so a missing `.eq(...)` only shows up on a
/// real device. This guard scans every client write for a row filter.
void main() {
  test('every client update and delete names the rows it changes', () {
    final offenders = <String>[];
    final writes = RegExp(r'\.(update\(|delete\(\))[\s\S]*?;');
    final filters = RegExp(r'\.(eq|neq|inFilter|match|filter|lt|lte|gt|gte|isFilter)\(');
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.endsWith('.g.dart') || file.path.endsWith('.freezed.dart')) continue;
      final source = file.readAsStringSync();
      for (final match in writes.allMatches(source)) {
        final statement = match.group(0)!;
        // Only Supabase query-builder calls (they follow `.from('table')`).
        final before = source.substring(0, match.start);
        final lastFrom = before.lastIndexOf(".from('");
        final lastSemicolon = before.lastIndexOf(';');
        if (lastFrom < 0 || lastFrom < lastSemicolon) continue;
        if (!filters.hasMatch(statement)) {
          final line = '\n'.allMatches(before).length + 1;
          offenders.add('${file.path}:$line');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Unfiltered writes: ${offenders.join(', ')}');
  });
}
