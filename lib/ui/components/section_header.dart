import 'package:flutter/material.dart';

import '../../widgets/ui/app_section_title.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return AppSectionTitle(
      title: title,
      actionLabel: actionLabel,
      onActionTap: onActionTap,
    );
  }
}
