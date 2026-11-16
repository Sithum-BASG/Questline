import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Compact error message under the auth heading.
class AuthErrorPill extends StatelessWidget {
  const AuthErrorPill({
    super.key,
    required this.message,
    this.onSignInTap,
  });

  final String message;
  final VoidCallback? onSignInTap;

  @override
  Widget build(BuildContext context) {
    final showAction = onSignInTap != null && message.contains('Sign in');
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.authErrorPill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 15, color: AppColors.authErrorText),
          const SizedBox(width: 6),
          Flexible(
            child: showAction
                ? Text.rich(
                    TextSpan(
                      style: AppText.authError,
                      children: _spansWithSignIn(message, onSignInTap!),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    message,
                    style: AppText.authError,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _spansWithSignIn(String message, VoidCallback onTap) {
    const needle = 'Sign in';
    final index = message.indexOf(needle);
    if (index < 0) return [TextSpan(text: message)];
    return [
      TextSpan(text: message.substring(0, index)),
      TextSpan(
        text: needle,
        style: AppText.authError.copyWith(
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()..onTap = onTap,
      ),
      TextSpan(text: message.substring(index + needle.length)),
    ];
  }
}
