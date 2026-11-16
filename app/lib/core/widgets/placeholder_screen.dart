import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import 'clay.dart';

/// Stand-in for a screen that a later phase fills in.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ClayHeader(title: title),
      body: Center(child: Text(title, style: AppText.body)),
    );
  }
}
