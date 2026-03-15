import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RewardedAdOutcome {
  const RewardedAdOutcome({
    required this.available,
    required this.shown,
    required this.earned,
  });

  final bool available;
  final bool shown;
  final bool earned;
}

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  static const bool _mockRewardedEnabled =
      bool.fromEnvironment('MOCK_REWARDED_ADS', defaultValue: false);

  Future<bool> isRewardedAdAvailable() async {
    return _mockRewardedEnabled;
  }

  Future<RewardedAdOutcome> showRewardedAd(BuildContext context) async {
    if (!_mockRewardedEnabled) {
      return const RewardedAdOutcome(
        available: false,
        shown: false,
        earned: false,
      );
    }
    if (!context.mounted) {
      return const RewardedAdOutcome(
        available: true,
        shown: false,
        earned: false,
      );
    }

    if (kDebugMode) {
      debugPrint('[rewarded] showing mock rewarded ad');
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'rewarded_ad',
      barrierColor: Colors.black.withOpacity(0.72),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return const _MockRewardedAdOverlay();
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    return const RewardedAdOutcome(
      available: true,
      shown: true,
      earned: true,
    );
  }
}

class _MockRewardedAdOverlay extends StatefulWidget {
  const _MockRewardedAdOverlay();

  @override
  State<_MockRewardedAdOverlay> createState() => _MockRewardedAdOverlayState();
}

class _MockRewardedAdOverlayState extends State<_MockRewardedAdOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();
    unawaited(_closeWhenDone());
  }

  Future<void> _closeWhenDone() async {
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF121A2C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3A4E73)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.ondemand_video_rounded,
              color: Color(0xFF7FB2FF),
              size: 34,
            ),
            const SizedBox(height: 10),
            const Text(
              'Watching bonus video...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _controller.value,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1B2A46),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4F8BFF),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

