import 'package:flutter/material.dart';
import 'wallet_chip.dart';

class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.timerText,
    required this.chipText,
    required this.nextText,
    required this.starsText,
    required this.onBack,
    required this.onHome,
    this.onClear,
    this.walletCoins,
    this.onWalletTap,
    this.showProgressRow = true,
  });

  final String timerText;
  final String chipText;
  final String nextText;
  final String starsText;
  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback? onClear;
  final int? walletCoins;
  final VoidCallback? onWalletTap;
  final bool showProgressRow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFE6E6EA) : const Color(0xFF202020);
    final pill = isDark ? const Color(0xFF2A2A2F) : const Color(0xFFF2F2F2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _NavButton(
              icon: Icons.arrow_back_rounded,
              label: 'Atras',
              onTap: onBack,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _NavButton(
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: onHome,
              isDark: isDark,
            ),
            const Spacer(),
            if (onClear != null)
              OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: fg,
                  side: BorderSide(
                    color: isDark ? const Color(0xFF7D7D82) : const Color(0xFF2D2D2D),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: pill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 16, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    timerText,
                    style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: pill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                chipText,
                style: TextStyle(fontWeight: FontWeight.w700, color: fg),
              ),
            ),
            const Spacer(),
            if (walletCoins != null)
              WalletChip(
                coins: walletCoins!,
                onTap: onWalletTap,
                compact: true,
              )
            else
              const SizedBox(width: 72),
          ],
        ),
        if (showProgressRow) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next $nextText',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              Text(
                'Stars $starsText',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2A2A2F) : Colors.white;
    final fg = isDark ? const Color(0xFFE7E7EB) : const Color(0xFF202020);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
