import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expanded = false,
    this.prominent = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expanded;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final height = prominent ? 64.0 : 52.0;
    final radius = prominent ? AppRadius.lg : AppRadius.md;
    final textStyle = AppTextStyles.button.copyWith(
      fontSize: prominent ? 21 : 15,
      color: _foreground(disabled),
    );

    final child = InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: Ink(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: prominent ? 22 : 16),
        decoration: BoxDecoration(
          color: _background(disabled),
          gradient: _gradient(disabled),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _border(disabled), width: 1.2),
          boxShadow: _shadows(disabled),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon,
                  size: prominent ? 24 : 18, color: _foreground(disabled)),
              const SizedBox(width: 8),
            ],
            Text(label, style: textStyle),
          ],
        ),
      ),
    );

    if (!expanded) return child;
    return SizedBox(width: double.infinity, child: child);
  }

  Color _background(bool disabled) {
    if (disabled) return AppColors.chipIdle;
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.surfaceElevated;
      case AppButtonVariant.outline:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return const Color(0xFF411E2A);
    }
  }

  Gradient? _gradient(bool disabled) {
    if (disabled) return null;
    switch (variant) {
      case AppButtonVariant.primary:
        return const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.primaryStrong],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
      case AppButtonVariant.danger:
        return null;
    }
  }

  Color _border(bool disabled) {
    if (disabled) return AppColors.softBorder;
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primaryStrong;
      case AppButtonVariant.secondary:
        return AppColors.softBorder;
      case AppButtonVariant.outline:
        return AppColors.border;
      case AppButtonVariant.danger:
        return AppColors.danger;
    }
  }

  Color _foreground(bool disabled) {
    if (disabled) return AppColors.textSecondary;
    switch (variant) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
        return AppColors.textPrimary;
      case AppButtonVariant.danger:
        return const Color(0xFFFFB3BE);
    }
  }

  List<BoxShadow>? _shadows(bool disabled) {
    if (disabled || variant != AppButtonVariant.primary) return null;
    return const <BoxShadow>[
      BoxShadow(
        color: Color(0x662E5BE7),
        blurRadius: 22,
        offset: Offset(0, 10),
      ),
    ];
  }
}
