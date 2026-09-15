import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionDirection { credit, debit }

class WalletTransactionModel {
  final String id;
  final String transactionId;
  final String userId;
  final String
  type; // BOOKING_PAYMENT, REFUND, WALLET_CREDIT, PROMOTIONAL_CREDIT, REWARD_EARN, REWARD_REDEEM
  final TransactionDirection direction;
  final int amountMinor; // In paise
  final String currency;
  final String status; // SUCCEEDED, PROCESSING, FAILED, CANCELLED
  final String source; // NAVIIGO_WALLET, RAZORPAY, REFUND_SERVICE
  final String? referenceType; // BOOKING, TRIP, PROMO
  final String? referenceId;
  final String? idempotencyKey;
  final String description;
  final DateTime? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.type,
    required this.direction,
    required this.amountMinor,
    this.currency = 'INR',
    this.status = 'SUCCEEDED',
    this.source = 'NAVIIGO_WALLET',
    this.referenceType,
    this.referenceId,
    this.idempotencyKey,
    required this.description,
    this.createdAt,
  });

  factory WalletTransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawDir = (data['direction'] ?? 'CREDIT').toString().toUpperCase();
    return WalletTransactionModel(
      id: doc.id,
      transactionId: (data['transactionId'] ?? doc.id).toString(),
      userId: (data['userId'] ?? '').toString(),
      type: (data['type'] ?? 'WALLET_CREDIT').toString(),
      direction: rawDir == 'DEBIT'
          ? TransactionDirection.debit
          : TransactionDirection.credit,
      amountMinor: (data['amountMinor'] as num?)?.toInt() ?? 0,
      currency: (data['currency'] ?? 'INR').toString(),
      status: (data['status'] ?? 'SUCCEEDED').toString(),
      source: (data['source'] ?? 'NAVIIGO_PLATFORM').toString(),
      referenceType: data['referenceType'] as String?,
      referenceId: data['referenceId'] as String?,
      idempotencyKey: data['idempotencyKey'] as String?,
      description: (data['description'] ?? 'Transaction').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  double get amountInr => amountMinor / 100.0;
  String get formattedAmount =>
      '${direction == TransactionDirection.credit ? '+' : '-'} ₹${amountInr.toStringAsFixed(2)}';
}
