import 'package:flutter/material.dart';

import '../theme/app_text.dart';

/// Stand-in for a screen that a later phase fills in.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: AppText.h2)),
      body: Center(child: Text(title, style: AppText.body)),
    );
  }
}
