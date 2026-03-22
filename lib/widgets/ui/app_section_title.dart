import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppTextStyles.sectionTitle),
              if ((subtitle ?? '').trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle!.trim(),
                  style: AppTextStyles.sectionSubtitle,
                ),
              ],
            ],
          ),
        ),
        if ((actionLabel ?? '').trim().isNotEmpty)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              actionLabel!.trim(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
