import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, thickness: 1, color: AppColors.authDivider)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: AppText.authOr),
          ),
          Expanded(child: Divider(height: 1, thickness: 1, color: AppColors.authDivider)),
        ],
      ),
    );
  }
}
