import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/wallet/domain/models/wallet_account_model.dart';
import 'package:naviigo_app/features/wallet/domain/models/wallet_transaction_model.dart';
import 'package:naviigo_app/features/places/domain/models/place_model.dart';

void main() {
  group('WalletAccountModel Unit Tests', () {
    test(
      'Calculates available and pending balance correctly in rupees from paise',
      () {
        const account = WalletAccountModel(
          availableMinor: 140050, // 1400.50 INR
          pendingMinor: 5000, // 50.00 INR
          currency: 'INR',
          rewardPoints: 250,
        );

        expect(account.availableInr, 1400.50);
        expect(account.pendingInr, 50.00);
        expect(account.formattedBalance, '₹1400.50');
        expect(account.rewardPoints, 250);
      },
    );

    test('Defaults with zero balance and default points', () {
      const account = WalletAccountModel();
      expect(account.availableMinor, 0);
      expect(account.availableInr, 0.0);
      expect(account.formattedBalance, '₹0.00');
      expect(account.currency, 'INR');
      expect(account.rewardPoints, 0);
    });
  });

  group('WalletTransactionModel Unit Tests', () {
    test('Calculates formatted amounts correctly for credit and debit', () {
      const creditTx = WalletTransactionModel(
        id: 'tx_01',
        transactionId: 'TXN-9821',
        userId: 'test_user',
        type: 'REFUND',
        direction: TransactionDirection.credit,
        amountMinor: 85000, // ₹850.00
        currency: 'INR',
        description: 'Flight Booking Cancellation Refund',
      );

      expect(creditTx.amountInr, 850.00);
      expect(creditTx.formattedAmount, '+ ₹850.00');

      const debitTx = WalletTransactionModel(
        id: 'tx_02',
        transactionId: 'TXN-9822',
        userId: 'test_user',
        type: 'BOOKING_PAYMENT',
        direction: TransactionDirection.debit,
        amountMinor: 30000, // ₹300.00
        currency: 'INR',
        description: 'Heritage Haveli Stay Credit Applied',
      );

      expect(debitTx.amountInr, 300.00);
      expect(debitTx.formattedAmount, '- ₹300.00');
    });
  });

  group('PlaceModel Unit Tests', () {
    test(
      'Parses backend JSON response correctly and resolves relative photo URLs',
      () {
        final json = {
          'id': 'place_amber_fort',
          'name': 'Amber Palace',
          'rating': 4.7,
          'userRatingsTotal': 118420,
          'priceLevel': 2,
          'vicinity': 'Devisinghpura, Amer, Jaipur',
          'lat': 26.9855,
          'lng': 75.8513,
          'isOpen': true,
          'types': ['tourist_attraction', 'point_of_interest'],
          'photo': '/api/places/photo?ref=test_ref_123',
          'description':
              'Iconic hilltop palace with ornate Rajput architecture',
          'phone': '+91 141 253 0101',
        };

        final place = PlaceModel.fromBackendJson(
          json,
          baseUrl: 'https://naviigo-website.onrender.com',
        );

        expect(place.id, 'place_amber_fort');
        expect(place.name, 'Amber Palace');
        expect(place.rating, 4.7);
        expect(place.userRatingsTotal, 118420);
        expect(place.isOpen, isTrue);
        expect(place.types.contains('tourist_attraction'), isTrue);
        expect(
          place.photoUrl,
          'https://naviigo-website.onrender.com/api/places/photo?ref=test_ref_123',
        );
        expect(place.phone, '+91 141 253 0101');
      },
    );
  });
}
