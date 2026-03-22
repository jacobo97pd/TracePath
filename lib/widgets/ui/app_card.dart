import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin = EdgeInsets.zero,
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.radius = AppRadius.lg,
    this.elevation = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;
  final Color borderColor;
  final double radius;
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: elevation
            ? const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.glow,
                  blurRadius: 26,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return widget;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: widget,
      ),
    );
  }
}
