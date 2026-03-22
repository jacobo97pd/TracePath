import 'package:flutter/material.dart';

import '../../services/coin_reward_overlay_service.dart';

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
    return _CoinDisplayCore(
      coins: coins,
      onTap: onTap,
      prominent: prominent,
    );
  }
}

class _CoinDisplayCore extends StatefulWidget {
  const _CoinDisplayCore({
    required this.coins,
    required this.onTap,
    required this.prominent,
  });

  final int coins;
  final VoidCallback? onTap;
  final bool prominent;

  @override
  State<_CoinDisplayCore> createState() => _CoinDisplayCoreState();
}

class _CoinDisplayCoreState extends State<_CoinDisplayCore>
    with SingleTickerProviderStateMixin {
  final GlobalKey _targetKey = GlobalKey();
  Object? _targetToken;
  late final AnimationController _pulseController;
  int _lastPulseVersion = 0;
  int _lastPendingVisualCoins = 0;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 52,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 48,
      ),
    ]).animate(_pulseController);
    _shakeAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.8)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.8, end: -1.4)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 23,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: -0.6)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.6, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 16,
      ),
    ]).animate(_pulseController);
    _targetToken =
        CoinRewardOverlayService.instance.registerTarget(_readGlobalRect);
    CoinRewardOverlayService.instance.addListener(_handleOverlayStateChanged);
  }

  @override
  void dispose() {
    CoinRewardOverlayService.instance
        .removeListener(_handleOverlayStateChanged);
    final token = _targetToken;
    if (token != null) {
      CoinRewardOverlayService.instance.unregisterTarget(token);
    }
    _pulseController.dispose();
    super.dispose();
  }

  void _handleOverlayStateChanged() {
    final pending = CoinRewardOverlayService.instance.pendingVisualCoins;
    if (pending != _lastPendingVisualCoins && mounted) {
      _lastPendingVisualCoins = pending;
      setState(() {});
    }
    final version = CoinRewardOverlayService.instance.pulseVersion;
    if (version != _lastPulseVersion) {
      _lastPulseVersion = version;
      _pulseController
        ..stop()
        ..forward(from: 0);
    }
  }

  Rect? _readGlobalRect() {
    final context = _targetKey.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  @override
  Widget build(BuildContext context) {
    final pendingVisualCoins =
        CoinRewardOverlayService.instance.pendingVisualCoins;
    final shownCoins =
        (widget.coins - pendingVisualCoins).clamp(0, widget.coins);
    final coinSize = widget.prominent ? 30.0 : 22.0;
    final fontSize = widget.prominent ? 22.0 : 16.0;
    final hPad = widget.prominent ? 18.0 : 14.0;
    final vPad = widget.prominent ? 12.0 : 10.0;
    final child = AnimatedBuilder(
      animation: _pulseController,
      builder: (context, inner) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: inner,
          ),
        );
      },
      child: Container(
        key: _targetKey,
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: widget.prominent
              ? const Color(0xFF243044)
              : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: widget.prominent
                ? const Color(0xFF4B628A)
                : const Color(0xFF334155),
          ),
          boxShadow: widget.prominent
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
            SizedBox(width: widget.prominent ? 10 : 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.22),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                '$shownCoins',
                key: ValueKey<int>(shownCoins),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: widget.onTap,
        child: child,
      ),
    );
  }
}
