import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.source,
    required this.referenceId,
    required this.createdAt,
  });

  final String id;
  final String type;
  final int amount;
  final String source;
  final String referenceId;
  final DateTime? createdAt;

  factory WalletTransaction.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final ts = data['createdAt'];
    return WalletTransaction(
      id: id,
      type: _readString(data['type'], fallback: 'reward'),
      amount: _readInt(data['amount']),
      source: _readString(data['source'], fallback: 'level_complete'),
      referenceId: _readString(data['referenceId'], fallback: ''),
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

