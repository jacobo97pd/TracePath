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

  static const double barHeight = 84;

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

    return SizedBox(
      height: barHeight + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 10 + bottomInset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 620
                ? 620.0
                : constraints.maxWidth;
            return Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: width,
                child: Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF14314F), Color(0xFF0D223A)],
                    ),
                    border: Border.all(
                      color: const Color(0xFF2A5378).withOpacity(0.95),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 5),
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
                ),
              ),
            );
          },
        ),
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
    final activeColor = const Color(0xFF95E8FF);
    final idleColor = const Color(0xFF97AFCB);
    final iconColor = selected ? activeColor : idleColor;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A5074), Color(0xFF234A6A)],
                )
              : null,
          border: Border.all(
            color: selected
                ? const Color(0xFF5A9BC6).withOpacity(0.95)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF49C7FF).withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: () => onTap(id),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  scale: selected ? 1.06 : 1,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: 20, color: iconColor),
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
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  style: AppTextStyles.caption.copyWith(
                    color: selected ? activeColor : idleColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
