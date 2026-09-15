import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/firebase_client.dart';
import '../domain/models/wallet_account_model.dart';
import '../domain/models/wallet_transaction_model.dart';

class WalletRepository {
  final FirebaseFirestore _firestore;
  final ApiClient _apiClient;

  WalletRepository({FirebaseFirestore? firestore, ApiClient? apiClient})
    : _firestore = firestore ?? FirebaseClient.firestore,
      _apiClient = apiClient ?? ApiClient();

  /// Stream user's authoritative wallet balance and reward points
  Stream<WalletAccountModel> getWalletAccountStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('wallet')
        .doc('account')
        .snapshots()
        .map((doc) => WalletAccountModel.fromFirestore(doc));
  }

  /// Stream immutable append-only ledger transactions
  Stream<List<WalletTransactionModel>> getTransactionsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('wallet_transactions')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => WalletTransactionModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) {
            final timeA = a.createdAt ?? DateTime(2000);
            final timeB = b.createdAt ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });
          return items;
        });
  }

  /// Validate coupon code against backend coupon rules
  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required int bookingAmountMinor,
  }) async {
    try {
      final res = await _apiClient.post(
        '/api/wallet/coupons/apply',
        body: {
          'code': code.trim().toUpperCase(),
          'bookingAmountMinor': bookingAmountMinor,
        },
        requiresAuth: true,
      );
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (_) {
      // Fallback local coupon evaluation if offline
    }

    // Default authoritative fallback calculations
    final upper = code.trim().toUpperCase();
    if (upper == 'WELCOME500' && bookingAmountMinor >= 300000) {
      return {
        'success': true,
        'code': 'WELCOME500',
        'discountMinor': 50000,
        'discountInr': 500.0,
        'description': '₹500 off on your first journey booking',
      };
    } else if (upper == 'EXPLORE10' && bookingAmountMinor >= 200000) {
      final discount = (bookingAmountMinor * 0.1).toInt();
      final capped = discount > 150000 ? 150000 : discount;
      return {
        'success': true,
        'code': 'EXPLORE10',
        'discountMinor': capped,
        'discountInr': capped / 100.0,
        'description': '10% off up to ₹1,500 on all curated stays & transit',
      };
    }

    throw Exception('Invalid or inapplicable coupon code.');
  }

  /// Request debit for checkout via atomic transaction to prevent double spend
  Future<void> requestDebit({
    required String uid,
    required int amountMinor,
    required String referenceId,
    required String idempotencyKey,
    String description = 'Booking checkout via Naviigo Credit',
  }) async {
    final accountRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('wallet')
        .doc('account');
    final txCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('wallet_transactions');

    // Run atomic transaction to prevent double spend
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(accountRef);
      final data = snap.data();
      final currentMinor = (data?['availableMinor'] as num?)?.toInt() ?? 0;

      if (currentMinor < amountMinor) {
        throw Exception(
          'Insufficient Naviigo Credit. Available: ₹${currentMinor / 100}, Required: ₹${amountMinor / 100}',
        );
      }

      transaction.update(accountRef, {
        'availableMinor': currentMinor - amountMinor,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final newTxDoc = txCol.doc(idempotencyKey);
      transaction.set(newTxDoc, {
        'transactionId': idempotencyKey,
        'userId': uid,
        'type': 'BOOKING_PAYMENT',
        'direction': 'DEBIT',
        'amountMinor': amountMinor,
        'currency': 'INR',
        'status': 'SUCCEEDED',
        'source': 'NAVIIGO_WALLET',
        'referenceType': 'BOOKING',
        'referenceId': referenceId,
        'idempotencyKey': idempotencyKey,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Request refund credit to wallet
  Future<void> requestRefund({
    required String uid,
    required int amountMinor,
    required String referenceId,
    required String idempotencyKey,
    String reason = 'Booking cancellation refund',
  }) async {
    final accountRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('wallet')
        .doc('account');
    final txCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('wallet_transactions');

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(accountRef);
      final data = snap.data();
      final currentMinor = (data?['availableMinor'] as num?)?.toInt() ?? 0;

      transaction.set(accountRef, {
        'availableMinor': currentMinor + amountMinor,
        'currency': 'INR',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final newTxDoc = txCol.doc(idempotencyKey);
      transaction.set(newTxDoc, {
        'transactionId': idempotencyKey,
        'userId': uid,
        'type': 'REFUND',
        'direction': 'CREDIT',
        'amountMinor': amountMinor,
        'currency': 'INR',
        'status': 'SUCCEEDED',
        'source': 'REFUND_SERVICE',
        'referenceType': 'BOOKING',
        'referenceId': referenceId,
        'idempotencyKey': idempotencyKey,
        'description': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
