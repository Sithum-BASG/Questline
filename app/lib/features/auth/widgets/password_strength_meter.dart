import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../password_strength.dart';

/// Three-pip password strength meter for sign-up.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final filled = passwordStrengthPips(password);
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < filled
                        ? AppColors.strengthFilled
                        : AppColors.strengthEmpty,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            passwordStrengthHint(password),
            style: AppText.authStrengthHint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
