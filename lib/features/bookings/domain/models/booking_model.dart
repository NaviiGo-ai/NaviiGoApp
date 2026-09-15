import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String type;
  final String status;
  final String from;
  final String to;
  final String date;
  final int travelers;
  final String providerName;
  final String? providerCode;
  final String? pnr;
  final double totalPrice;
  final String currency;
  final String? redirectUrl;
  final String? redirectProvider;
  final DateTime? createdAt;

  const BookingModel({
    required this.id,
    required this.type,
    required this.status,
    required this.from,
    required this.to,
    required this.date,
    this.travelers = 1,
    required this.providerName,
    this.providerCode,
    this.pnr,
    this.totalPrice = 0.0,
    this.currency = 'INR',
    this.redirectUrl,
    this.redirectProvider,
    this.createdAt,
  });

  factory BookingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return BookingModel(
      id: doc.id,
      type: (data['type'] ?? 'flight').toString(),
      status: (data['status'] ?? 'confirmed').toString(),
      from: (data['from'] ?? '').toString(),
      to: (data['to'] ?? '').toString(),
      date: (data['date'] ?? '').toString(),
      travelers: (data['travelers'] as num?)?.toInt() ?? 1,
      providerName: (data['providerName'] ?? 'Operator').toString(),
      providerCode: data['providerCode'] as String?,
      pnr: data['pnr'] as String?,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      currency: (data['currency'] ?? 'INR').toString(),
      redirectUrl: data['redirectUrl'] as String?,
      redirectProvider: data['redirectProvider'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
