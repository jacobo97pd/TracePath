import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../ui/components/app_card.dart' as modern;

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
    return modern.AppCard(
      onTap: onTap,
      padding: padding,
      margin: margin,
      color: color,
      borderColor: borderColor,
      radius: radius,
      elevation: elevation,
      child: child,
    );
  }
}
