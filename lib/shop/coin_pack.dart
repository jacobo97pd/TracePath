class CoinPack {
  const CoinPack({
    required this.id,
    required this.title,
    required this.description,
    required this.coins,
    required this.bonusCoins,
    required this.totalCoins,
    required this.priceLabel,
    required this.productIdAndroid,
    required this.productIdIos,
    required this.imagePath,
    required this.sortOrder,
    required this.tag,
    required this.active,
    this.isFallback = false,
  });

  final String id;
  final String title;
  final String description;
  final int coins;
  final int bonusCoins;
  final int totalCoins;
  final String priceLabel;
  final String productIdAndroid;
  final String productIdIos;
  final String imagePath;
  final int sortOrder;
  final String tag;
  final bool active;
  final bool isFallback;

  factory CoinPack.fromFirestore({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final id = _readString(data['id']).ifEmpty(docId);
    final title = _readString(data['title']).ifEmpty(_humanizeId(id));
    final description = _readString(data['description']);
    final coins = _readInt(data['coins']);
    final bonusCoins = _readInt(data['bonusCoins']);
    final totalCoinsRaw = _readInt(data['totalCoins']);
    final totalCoins = totalCoinsRaw > 0 ? totalCoinsRaw : (coins + bonusCoins);
    final priceLabel = _readString(data['priceLabel']);
    final productIdAndroid = _readString(data['productIdAndroid']);
    final productIdIos = _readString(data['productIdIos']);
    final imagePath = _readString(data['imagePath']);
    final sortOrder = _readInt(data['sortOrder']);
    final tag = _readString(data['tag']);
    final active = _readActive(data['active']);

    return CoinPack(
      id: id,
      title: title,
      description: description,
      coins: coins,
      bonusCoins: bonusCoins,
      totalCoins: totalCoins,
      priceLabel: priceLabel,
      productIdAndroid: productIdAndroid,
      productIdIos: productIdIos,
      imagePath: imagePath,
      sortOrder: sortOrder,
      tag: tag,
      active: active,
    );
  }

  factory CoinPack.fromDoc({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    return CoinPack.fromFirestore(docId: docId, data: data);
  }

  static String _readString(Object? value) {
    if (value is String) return value.trim();
    return '';
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      final direct = int.tryParse(trimmed);
      if (direct != null) return direct;
      final asDouble = double.tryParse(trimmed);
      if (asDouble != null) return asDouble.toInt();
      final compact = trimmed.replaceAll(RegExp(r'[^0-9\-]'), '');
      return int.tryParse(compact) ?? 0;
    }
    return 0;
  }

  static bool _readBool(Object? value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return defaultValue;
  }

  static bool _readActive(Object? value) {
    if (value == null) return true;
    return _readBool(value, defaultValue: false);
  }

  static String _humanizeId(String raw) {
    final normalized = raw.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (normalized.isEmpty) return 'Coin Pack';
    return normalized
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
