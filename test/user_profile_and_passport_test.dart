import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/profile/domain/models/user_profile_model.dart';
import 'package:naviigo_app/features/bookings/domain/models/passport_model.dart';
import 'package:naviigo_app/features/bookings/domain/models/saved_place_model.dart';
import 'package:naviigo_app/features/bookings/domain/models/booking_model.dart';

void main() {
  group('Domain Models Unit Tests', () {
    test('UserProfileModel calculates initials correctly', () {
      const user1 = UserProfileModel(
        uid: 'user_1',
        displayName: 'Rohan Sharma',
        email: 'rohan@example.com',
      );
      expect(user1.initials, 'RS');

      const user2 = UserProfileModel(
        uid: 'user_2',
        displayName: 'Priya',
        email: 'priya@example.com',
      );
      expect(user2.initials, 'PR');

      const user3 = UserProfileModel(
        uid: 'user_3',
        displayName: null,
        email: 'nomad@naviigo.com',
      );
      expect(user3.initials, 'NO');
    });

    test(
      'PassportStatsModel and PassportStampModel default and properties',
      () {
        const stats = PassportStatsModel(
          totalStamps: 4,
          totalXP: 550,
          level: 3,
          statesVisited: ['Rajasthan', 'Kerala', 'Goa'],
        );
        expect(stats.totalStamps, 4);
        expect(stats.level, 3);
        expect(stats.statesVisited.length, 3);

        const stamp = PassportStampModel(
          id: 'stamp_1',
          name: 'Hawa Mahal',
          location: 'Jaipur',
          state: 'Rajasthan',
          icon: '🏛️',
          xpEarned: 150,
        );
        expect(stamp.name, 'Hawa Mahal');
        expect(stamp.xpEarned, 150);
      },
    );

    test('SavedPlaceModel and BookingModel instantiation', () {
      const place = SavedPlaceModel(
        id: 'place_1',
        name: 'Taj Mahal',
        type: 'Monument',
        location: 'Agra, Uttar Pradesh',
      );
      expect(place.id, 'place_1');
      expect(place.name, 'Taj Mahal');

      const booking = BookingModel(
        id: 'book_1',
        type: 'flight',
        status: 'confirmed',
        from: 'DEL',
        to: 'JAI',
        date: '2026-11-20',
        providerName: 'IndiGo',
        pnr: '6E-4521',
        totalPrice: 4200.0,
      );
      expect(booking.pnr, '6E-4521');
      expect(booking.totalPrice, 4200.0);
    });
  });
}
