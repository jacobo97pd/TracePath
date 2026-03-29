import 'package:flutter/material.dart';

class PresenceDot extends StatelessWidget {
  const PresenceDot({
    super.key,
    required this.isOnline,
    this.size = 10,
  });

  final bool isOnline;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: const Color(0xFF0F172A), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.42),
            blurRadius: 6,
            spreadRadius: 0.3,
          ),
        ],
      ),
    );
  }
}

