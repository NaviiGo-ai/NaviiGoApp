import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/firebase_client.dart';
import '../domain/models/wallet_account_model.dart';
import '../domain/models/wallet_transaction_model.dart';

/// Read-only view of the server-authoritative Naviigo Credit ledger.
///
/// Every mutation — debit, refund, coupon redemption — is performed by the
/// Naviigo backend, which owns the balance and enforces idempotency. This
/// client never writes `availableMinor`, so a tampered or repackaged app
/// cannot mint credit or spend the same rupees twice.
///
/// The wallet owner is always derived from the caller's verified Firebase ID
/// token on the server. No method here takes a `uid` to act on, because a
/// client must never get to nominate whose balance it is moving.
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

  /// Validate a coupon against the server.
  ///
  /// There is deliberately no local fallback. The server owns the eligibility
  /// rules, the per-user usage limits and the expiry; evaluating coupons on
  /// the device would let anyone with the APK grant themselves a discount and
  /// redeem the same code repeatedly.
  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required int bookingAmountMinor,
  }) async {
    final res = await _apiClient.post(
      '/wallet/coupons/apply',
      body: {
        'code': code.trim().toUpperCase(),
        'bookingAmountMinor': bookingAmountMinor,
      },
      requiresAuth: true,
    );

    if (res is! Map) {
      throw const ServerException(
        'Unexpected response while validating the coupon.',
      );
    }
    return Map<String, dynamic>.from(res);
  }

  /// Ask the server to debit Naviigo Credit for a booking.
  ///
  /// [idempotencyKey] must be stable for a given checkout attempt so that a
  /// retry (flaky network, double tap) replays the original result instead of
  /// charging twice. The server performs the balance check and the ledger
  /// append inside a single transaction.
  Future<Map<String, dynamic>> requestDebit({
    required int amountMinor,
    required String referenceId,
    required String idempotencyKey,
    String description = 'Booking checkout via Naviigo Credit',
  }) async {
    final res = await _apiClient.post(
      '/wallet/debit',
      body: {
        'amountMinor': amountMinor,
        'referenceId': referenceId,
        'idempotencyKey': idempotencyKey,
        'description': description,
      },
      requiresAuth: true,
    );

    if (res is! Map) {
      throw const ServerException(
        'Unexpected response while debiting Naviigo Credit.',
      );
    }
    return Map<String, dynamic>.from(res);
  }

  /// Ask the server to credit a refund back to Naviigo Credit.
  ///
  /// Refunds are server-initiated against a real cancelled reference and are
  /// idempotent on [idempotencyKey], so a booking can never be refunded twice.
  Future<Map<String, dynamic>> requestRefund({
    required int amountMinor,
    required String referenceId,
    required String idempotencyKey,
    String reason = 'Booking cancellation refund',
  }) async {
    final res = await _apiClient.post(
      '/wallet/refund',
      body: {
        'amountMinor': amountMinor,
        'referenceId': referenceId,
        'idempotencyKey': idempotencyKey,
        'reason': reason,
      },
      requiresAuth: true,
    );

    if (res is! Map) {
      throw const ServerException(
        'Unexpected response while refunding Naviigo Credit.',
      );
    }
    return Map<String, dynamic>.from(res);
  }
}
