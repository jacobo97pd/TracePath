import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
    this.trailing,
    this.padding,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textSecondary;
    final bg = selected ? AppColors.chipSelected : AppColors.chipIdle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.softBorder,
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (leading != null) ...<Widget>[
                IconTheme(
                  data: IconThemeData(color: fg, size: 15),
                  child: leading!,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.chip.copyWith(color: fg),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 6),
                IconTheme(
                  data: IconThemeData(color: fg, size: 15),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
