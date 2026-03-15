import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseRecord {
  const PurchaseRecord({
    required this.id,
    required this.productId,
    required this.platform,
    required this.status,
    required this.coinsGranted,
    required this.receiptVerified,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String platform;
  final String status;
  final int coinsGranted;
  final bool receiptVerified;
  final DateTime? createdAt;

  factory PurchaseRecord.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return PurchaseRecord(
      id: id,
      productId: _readString(data['productId'], fallback: ''),
      platform: _readString(data['platform'], fallback: 'android'),
      status: _readString(data['status'], fallback: 'pending'),
      coinsGranted: _readInt(data['coinsGranted']),
      receiptVerified: data['receiptVerified'] == true,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static String _readString(Object? value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }
}

