import 'package:cloud_firestore/cloud_firestore.dart';

class WalletAccountModel {
  final int availableMinor; // In paise
  final int pendingMinor; // In paise
  final String currency;
  final int rewardPoints;
  final DateTime? updatedAt;

  const WalletAccountModel({
    this.availableMinor = 0,
    this.pendingMinor = 0,
    this.currency = 'INR',
    this.rewardPoints = 0,
    this.updatedAt,
  });

  factory WalletAccountModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (!doc.exists) return const WalletAccountModel(rewardPoints: 150);
    final data = doc.data() ?? {};
    return WalletAccountModel(
      availableMinor: (data['availableMinor'] as num?)?.toInt() ?? 0,
      pendingMinor: (data['pendingMinor'] as num?)?.toInt() ?? 0,
      currency: (data['currency'] ?? 'INR').toString(),
      rewardPoints: (data['rewardPoints'] as num?)?.toInt() ?? 150,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  double get availableInr => availableMinor / 100.0;
  double get pendingInr => pendingMinor / 100.0;
  String get formattedBalance => '₹${availableInr.toStringAsFixed(2)}';
}
