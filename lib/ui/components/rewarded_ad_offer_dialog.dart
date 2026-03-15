import 'package:flutter/material.dart';

enum RewardedAdOfferAction {
  watch,
  skip,
}

class RewardedAdOfferDialog extends StatefulWidget {
  const RewardedAdOfferDialog({
    super.key,
    required this.bonusCoins,
  });

  final int bonusCoins;

  static Future<RewardedAdOfferAction> show(
    BuildContext context, {
    required int bonusCoins,
  }) async {
    final result = await showGeneralDialog<RewardedAdOfferAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'rewarded_offer',
      barrierColor: Colors.black.withOpacity(0.58),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return RewardedAdOfferDialog(bonusCoins: bonusCoins);
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return result ?? RewardedAdOfferAction.skip;
  }

  @override
  State<RewardedAdOfferDialog> createState() => _RewardedAdOfferDialogState();
}

class _RewardedAdOfferDialogState extends State<RewardedAdOfferDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF17233D),
                Color(0xFF121B2F),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF44639A), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final t = _pulseController.value;
                  return Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD166).withOpacity(0.15),
                      border: Border.all(
                        color: const Color(0xFFFFD166).withOpacity(0.35 + (0.3 * t)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC857).withOpacity(0.12 + (0.12 * t)),
                          blurRadius: 16 + (6 * t),
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFFFD166),
                      size: 30,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'BONUS REWARD',
                style: TextStyle(
                  color: Color(0xFF9CC2FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Watch a short video\nand earn +${widget.bonusCoins} coins',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(RewardedAdOfferAction.watch),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                  label: const Text(
                    'Watch & Earn',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(RewardedAdOfferAction.skip),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4A5D81)),
                    foregroundColor: const Color(0xFFD5E0F5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'No Thanks',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

