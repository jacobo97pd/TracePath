import 'dart:math' as math;
import 'package:flutter/material.dart';

class CoinRewardRequest {
  const CoinRewardRequest({
    required this.origin,
    required this.visualCount,
    required this.amount,
    required this.duration,
    required this.id,
    this.onCompleted,
  });

  final Offset origin;
  final int visualCount;
  final int amount;
  final Duration duration;
  final int id;
  final VoidCallback? onCompleted;
}

class CoinRewardOverlayService extends ChangeNotifier {
  CoinRewardOverlayService._();

  static final CoinRewardOverlayService instance = CoinRewardOverlayService._();

  final ValueNotifier<CoinRewardRequest?> activeRequest =
      ValueNotifier<CoinRewardRequest?>(null);

  final Map<Object, Rect? Function()> _targetReaders =
      <Object, Rect? Function()>{};
  int _requestId = 0;
  int _pendingVisualCoins = 0;
  int _pulseVersion = 0;

  int get pendingVisualCoins => _pendingVisualCoins;
  int get pulseVersion => _pulseVersion;

  Object registerTarget(Rect? Function() reader) {
    final token = Object();
    _targetReaders[token] = reader;
    return token;
  }

  void unregisterTarget(Object token) {
    _targetReaders.remove(token);
  }

  Rect? resolveTargetRect() {
    Rect? selected;
    for (final reader in _targetReaders.values) {
      final rect = reader();
      if (rect == null) continue;
      if (selected == null || rect.center.dy < selected.center.dy) {
        selected = rect;
      }
    }
    return selected;
  }

  Future<void> showCoinRewardAnimation({
    Offset? origin,
    int visualCount = 14,
    required int amount,
    Duration duration = const Duration(milliseconds: 1200),
    VoidCallback? onCompleted,
  }) async {
    if (amount <= 0) return;
    final safeVisual = visualCount.clamp(6, 30);
    final request = CoinRewardRequest(
      origin: origin ?? const Offset(0.5, 0.72),
      visualCount: safeVisual,
      amount: amount,
      duration: duration,
      id: ++_requestId,
      onCompleted: onCompleted,
    );
    _pendingVisualCoins += amount;
    notifyListeners();
    activeRequest.value = request;
  }

  void completeRequest(CoinRewardRequest request) {
    if (activeRequest.value?.id == request.id) {
      activeRequest.value = null;
    }
    _pendingVisualCoins = math.max(0, _pendingVisualCoins - request.amount);
    _pulseVersion += 1;
    request.onCompleted?.call();
    notifyListeners();
  }
}
