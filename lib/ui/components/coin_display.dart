import 'package:flutter/material.dart';

class CoinDisplay extends StatelessWidget {
  const CoinDisplay({
    super.key,
    required this.coins,
    this.onTap,
    this.prominent = false,
  });

  final int coins;
  final VoidCallback? onTap;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final coinSize = prominent ? 30.0 : 22.0;
    final fontSize = prominent ? 22.0 : 16.0;
    final hPad = prominent ? 18.0 : 14.0;
    final vPad = prominent ? 12.0 : 10.0;
    final child = Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: prominent ? const Color(0xFF243044) : const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: prominent ? const Color(0xFF4B628A) : const Color(0xFF334155),
        ),
        boxShadow: prominent
            ? const [
                BoxShadow(
                  color: Color(0x4D1D4ED8),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(
              'assets/branding/coin_tracepath.png',
              width: coinSize,
              height: coinSize,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: prominent ? 10 : 8),
          Text(
            '$coins',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
