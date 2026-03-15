import 'package:flutter/material.dart';

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
    final bg = outlined ? Colors.transparent : const Color(0xFF3E79FF);
    final fg = outlined ? const Color(0xFFDCE8FF) : Colors.white;
    final border = outlined
        ? BorderSide(color: const Color(0xFF2C467A), width: 1.2)
        : BorderSide.none;

    final buttonHeight = prominent ? 66.0 : 52.0;
    final fontSize = prominent ? 21.0 : 15.0;
    final iconSize = prominent ? 24.0 : 18.0;
    final radius = prominent ? 20.0 : 16.0;

    final button = InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: Ink(
        height: buttonHeight,
        padding: EdgeInsets.symmetric(horizontal: prominent ? 22 : 16),
        decoration: BoxDecoration(
          gradient: (!outlined && prominent)
              ? const LinearGradient(
                  colors: [Color(0xFF4A7CFF), Color(0xFF2E5BE7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: outlined || prominent ? bg : bg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.fromBorderSide(border),
          boxShadow: (!outlined && prominent)
              ? const [
                  BoxShadow(
                    color: Color(0x662E5BE7),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
                letterSpacing: prominent ? 0.4 : 0.2,
              ),
            ),
          ],
        ),
      ),
    );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
