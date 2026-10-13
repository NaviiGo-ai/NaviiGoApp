import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/features/bookings/data/passport_repository.dart';
import 'package:naviigo_app/features/bookings/domain/models/passport_model.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/trips/presentation/providers/trip_provider.dart';

class _User extends Fake implements User {
  _User(this.uid);

  @override
  final String uid;
}

TripItineraryModel _trip(String id, String status, {bool ephemeral = false}) {
  return TripItineraryModel.fromMap(id, {
    'id': id,
    'uuid': id,
    'destId': 'jaipur',
    'destName': 'Jaipur',
    'userId': 'owner-a',
    'status': status,
    'isEphemeral': ephemeral,
    'dayPlans': [
      {
        'day': 1,
        'activities': [
          {'title': 'Amber Fort'},
        ],
      },
    ],
  });
}

void main() {
  test(
    'history/upcoming/live providers use lifecycle and exclude previews',
    () async {
      final container = ProviderContainer(
        overrides: [
          userTripsStreamProvider.overrideWith(
            (ref) => Stream.value([
              _trip('completed', 'completed'),
              _trip('cancelled', 'cancelled'),
              _trip('active', 'active'),
              _trip('upcoming', 'upcoming'),
              _trip('preview', 'completed', ephemeral: true),
            ]),
          ),
          currentUserProvider.overrideWithValue(_User('owner-a')),
        ],
      );
      addTearDown(container.dispose);

      await container.read(userTripsStreamProvider.future);

      expect(container.read(activeTripProvider)?.id, 'active');
      expect(
        container.read(upcomingTripsProvider).map((trip) => trip.id).toList(),
        ['upcoming'],
      );
      expect(
        container.read(pastTripsProvider).map((trip) => trip.id).toList(),
        ['completed'],
      );
    },
  );

  test(
    'cancelled journeys never enter history or Passport journey counts',
    () async {
      final container = ProviderContainer(
        overrides: [
          userTripsStreamProvider.overrideWith(
            (ref) => Stream.value([_trip('cancelled', 'cancelled')]),
          ),
          currentUserProvider.overrideWithValue(_User('owner-a')),
        ],
      );
      addTearDown(container.dispose);
      await container.read(userTripsStreamProvider.future);

      expect(container.read(activeTripProvider), isNull);
      expect(container.read(pastTripsProvider), isEmpty);
    },
  );

  test('Passport award keys are deterministic and owner-scoped by path', () {
    final first = PassportRepository.deterministicAwardKey('trip-1', 'temple');
    final retry = PassportRepository.deterministicAwardKey('trip-1', 'temple');
    final differentNote = PassportRepository.deterministicAwardKey(
      'trip-1',
      'market',
    );

    expect(first, retry);
    expect(first, isNot(differentNote));
    expect(first, startsWith('moment_'));
  });

  test('Passport model preserves verification and stable award metadata', () {
    const stamp = PassportStampModel(
      id: 'award-1',
      awardKey: 'award-1',
      name: 'Amber Fort',
      location: 'Jaipur',
      state: 'Rajasthan',
      isVerified: true,
      verificationMethod: 'server_receipt',
    );

    final payload = stamp.toFirestore();
    expect(payload['awardKey'], 'award-1');
    expect(payload['isVerified'], isTrue);
    expect(payload['verificationMethod'], 'server_receipt');
  });
}
