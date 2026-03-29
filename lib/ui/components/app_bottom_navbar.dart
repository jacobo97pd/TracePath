import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppBottomNavbar extends StatelessWidget {
  const AppBottomNavbar({
    super.key,
    required this.selectedTabId,
    required this.onTabTap,
    required this.homeLabel,
    required this.shopLabel,
    required this.cardsLabel,
    required this.duelLabel,
    required this.profileLabel,
    this.profileBadgeCount = 0,
  });

  static const double barHeight = 66;

  final String selectedTabId;
  final ValueChanged<String> onTabTap;
  final String homeLabel;
  final String shopLabel;
  final String cardsLabel;
  final String duelLabel;
  final String profileLabel;
  final int profileBadgeCount;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      height: barHeight + bottomInset,
      padding: EdgeInsets.fromLTRB(10, 6, 10, 6 + bottomInset),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavTabButton(
            id: 'home',
            icon: Icons.home_rounded,
            label: homeLabel,
            selected: selectedTabId == 'home',
            onTap: onTabTap,
          ),
          _NavTabButton(
            id: 'shop',
            icon: Icons.storefront_rounded,
            label: shopLabel,
            selected: selectedTabId == 'shop',
            onTap: onTabTap,
          ),
          _NavTabButton(
            id: 'cards',
            icon: Icons.style_rounded,
            label: cardsLabel,
            selected: selectedTabId == 'cards',
            onTap: onTabTap,
          ),
          _NavTabButton(
            id: 'duel',
            icon: Icons.flash_on_rounded,
            label: duelLabel,
            selected: selectedTabId == 'duel',
            onTap: onTabTap,
          ),
          _NavTabButton(
            id: 'profile',
            icon: Icons.person_outline_rounded,
            label: profileLabel,
            selected: selectedTabId == 'profile',
            badgeCount: profileBadgeCount,
            onTap: onTabTap,
          ),
        ],
      ),
    );
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.id,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String id;
  final IconData icon;
  final String label;
  final bool selected;
  final int badgeCount;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.accent;
    final idleColor = AppColors.textSecondary;
    final iconColor = selected ? activeColor : idleColor;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                scale: selected ? 1.08 : 1.0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 21, color: iconColor),
                    if (badgeCount > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          width: 15,
                          height: 15,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? activeColor : idleColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
