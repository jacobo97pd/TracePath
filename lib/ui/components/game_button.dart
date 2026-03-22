import 'package:flutter/material.dart';

import '../../widgets/ui/app_button.dart';

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expanded = false,
    this.outlined = false,
    this.prominent = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;
  final bool outlined;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onTap: onTap,
      icon: icon,
      expanded: expanded,
      prominent: prominent,
      variant: outlined ? AppButtonVariant.outline : AppButtonVariant.primary,
    );
  }
}
