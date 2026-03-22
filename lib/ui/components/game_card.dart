import 'package:flutter/material.dart';

import '../../widgets/ui/app_card.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}
