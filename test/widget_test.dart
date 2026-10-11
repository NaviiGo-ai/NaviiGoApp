import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naviigo_app/features/bookings/presentation/pages/payment_history_page.dart';
import 'package:naviigo_app/features/bookings/presentation/pages/digital_passport_page.dart';
import 'package:naviigo_app/features/bookings/presentation/pages/bookings_page.dart';
import 'package:naviigo_app/features/bookings/presentation/pages/saved_places_page.dart';
import 'package:naviigo_app/features/bookings/domain/models/booking_model.dart';
import 'package:naviigo_app/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:naviigo_app/features/more/presentation/pages/settings_page.dart';
import 'package:naviigo_app/features/more/presentation/pages/help_support_page.dart';
import 'package:naviigo_app/features/wallet/domain/models/wallet_account_model.dart';
import 'package:naviigo_app/features/wallet/domain/models/wallet_transaction_model.dart';
import 'package:naviigo_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:naviigo_app/features/bookings/domain/models/passport_model.dart';
import 'package:naviigo_app/features/bookings/presentation/providers/passport_provider.dart';
import 'package:naviigo_app/features/bookings/presentation/providers/saved_places_provider.dart';
import 'package:naviigo_app/features/trips/presentation/providers/trip_provider.dart';
import 'package:naviigo_app/features/trips/domain/models/trip_itinerary_model.dart';
import 'package:naviigo_app/features/bookings/domain/models/saved_place_model.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/features/profile/domain/models/user_profile_model.dart';
import 'package:naviigo_app/features/profile/presentation/providers/user_provider.dart';

Widget _buildTestableWidget({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) =>
          MaterialApp(debugShowCheckedModeBanner: false, home: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaymentHistoryPage Widget Tests', () {
    final mockAccount = const WalletAccountModel(
      availableMinor: 250000, // ₹2,500.00
      pendingMinor: 0,
      currency: 'INR',
      rewardPoints: 450,
    );

    final mockTransactions = [
      WalletTransactionModel(
        id: 'tx_1',
        transactionId: 'TXN-1001',
        userId: 'user_123',
        type: 'REFUND_PAYMENT',
        direction: TransactionDirection.credit,
        amountMinor: 120000, // ₹1,200.00
        description: 'Jaipur Haveli Booking Refund',
        status: 'SUCCEEDED',
        source: 'REFUND_SERVICE',
        referenceId: 'REF-8891',
        createdAt: DateTime(2026, 9, 14, 10, 30),
      ),
      WalletTransactionModel(
        id: 'tx_2',
        transactionId: 'TXN-1002',
        userId: 'user_123',
        type: 'BOOKING_DEBIT',
        direction: TransactionDirection.debit,
        amountMinor: 85000, // ₹850.00
        description: 'Varanasi Ghat Guide Booking',
        status: 'SUCCEEDED',
        source: 'NAVIIGO_WALLET',
        referenceId: 'BKG-4421',
        createdAt: DateTime(2026, 9, 12, 14, 0),
      ),
    ];

    testWidgets('Renders wallet balance, points, and transaction cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const PaymentHistoryPage(),
          overrides: [
            walletAccountStreamProvider.overrideWith(
              (ref) => Stream.value(mockAccount),
            ),
            walletTransactionsStreamProvider.overrideWith(
              (ref) => Stream.value(mockTransactions),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and balance
      expect(find.text('TRAVEL WALLET & LEDGER'), findsOneWidget);
      expect(find.text('NAVIIGO CREDIT'), findsOneWidget);
      expect(find.text('₹2500.00'), findsOneWidget);
      expect(find.text('450 Points'), findsOneWidget);

      // Verify transaction list items
      expect(find.text('Jaipur Haveli Booking Refund'), findsOneWidget);
      expect(find.text('+ ₹1200.00'), findsOneWidget);
      expect(find.text('Varanasi Ghat Guide Booking'), findsOneWidget);
      expect(find.text('- ₹850.00'), findsOneWidget);
    });

    testWidgets('Filters transactions when tapping filter chips', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const PaymentHistoryPage(),
          overrides: [
            walletAccountStreamProvider.overrideWith(
              (ref) => Stream.value(mockAccount),
            ),
            walletTransactionsStreamProvider.overrideWith(
              (ref) => Stream.value(mockTransactions),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'REFUND' filter chip
      final refundChip = find.text('REFUND');
      expect(refundChip, findsOneWidget);
      await tester.tap(refundChip);
      await tester.pumpAndSettle();

      // Only refund transaction should be visible
      expect(find.text('Jaipur Haveli Booking Refund'), findsOneWidget);
      expect(find.text('Varanasi Ghat Guide Booking'), findsNothing);

      // Tap on 'TRIP' filter chip
      final tripChip = find.text('TRIP');
      expect(tripChip, findsOneWidget);
      await tester.tap(tripChip);
      await tester.pumpAndSettle();

      // Only booking transaction should be visible
      expect(find.text('Varanasi Ghat Guide Booking'), findsOneWidget);
      expect(find.text('Jaipur Haveli Booking Refund'), findsNothing);
    });

    testWidgets('Opens transaction detail bottom sheet on card tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const PaymentHistoryPage(),
          overrides: [
            walletAccountStreamProvider.overrideWith(
              (ref) => Stream.value(mockAccount),
            ),
            walletTransactionsStreamProvider.overrideWith(
              (ref) => Stream.value(mockTransactions),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Tap the first transaction item
      await tester.tap(find.text('Jaipur Haveli Booking Refund'));
      await tester.pumpAndSettle();

      // Verify details modal bottom sheet
      expect(find.text('TRANSACTION DETAILS'), findsOneWidget);
      expect(find.text('SUCCEEDED'), findsOneWidget);
      expect(find.text('REFUND_SERVICE'), findsOneWidget);
      expect(find.text('REF-8891'), findsOneWidget);
    });
  });

  group('SettingsPage Widget Tests', () {
    const mockProfile = UserProfileModel(
      uid: 'user_123',
      displayName: 'Naviigo Explorer',
      email: 'traveler@naviigo.in',
      totalTrips: 3,
      totalBookings: 2,
    );

    testWidgets('Renders settings toggles, links, and log out dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestableWidget(
          child: const SettingsPage(),
          overrides: [
            userProfileStreamProvider.overrideWith(
              (ref) => Stream.value(mockProfile),
            ),
            currentUserProvider.overrideWithValue(null),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and section titles
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('ACCOUNT & WALLET'), findsOneWidget);
      expect(find.text('SUPPORT & LEGAL'), findsOneWidget);

      // Verify links
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Location Services'), findsOneWidget);
      expect(find.text('Personal Profile & Travel Style'), findsOneWidget);
      expect(find.text('Travel Wallet & Credits'), findsOneWidget);
      expect(find.text('Bookings & Offline Vouchers'), findsOneWidget);
      expect(find.text('Help & Support Concierge'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);

      // Verify switch toggles
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));
      expect(find.text('Adaptive Appearance'), findsOneWidget);

      // Tap Push Notifications switch
      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();

      // Tap Location Services switch
      await tester.tap(switches.last);
      await tester.pumpAndSettle();

      // Tap Log Out button to trigger confirmation dialog
      final logOutButton = find.text('Log Out of Naviigo');
      expect(logOutButton, findsOneWidget);
      await tester.tap(logOutButton);
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Log Out'), findsWidgets);
      expect(
        find.text('Are you sure you want to log out of your Naviigo account?'),
        findsOneWidget,
      );

      // Tap Cancel to dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(
        find.text('Are you sure you want to log out of your Naviigo account?'),
        findsNothing,
      );
    });

    testWidgets('Opens Privacy Policy and Terms dialogs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestableWidget(
          child: const SettingsPage(),
          overrides: [
            userProfileStreamProvider.overrideWith(
              (ref) => Stream.value(mockProfile),
            ),
            currentUserProvider.overrideWithValue(null),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Tap Privacy Policy link
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Naviigo is committed to protecting your travel telemetry, location privacy, and booking details. Your active tracking sessions are private, temporary, and shared only with your authorized Buddies.',
        ),
        findsOneWidget,
      );

      // Dismiss dialog
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      // Tap Terms of Service link
      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'All bookings, itinerary generations, and wallet credits are governed by the Naviigo Platform Terms. Prices and external provider reservations are subject to partner confirmation.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
    });
  });

  group('HelpSupportPage Widget Tests', () {
    testWidgets('Renders FAQ accordions and AI chat modal sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(child: const HelpSupportPage()),
      );

      await tester.pumpAndSettle();

      // Verify titles and FAQs
      expect(find.text('CONCIERGE & SUPPORT'), findsOneWidget);
      expect(find.text('NaviiGo AI Concierge'), findsOneWidget);
      expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);
      expect(find.text('How do I cancel my booking or stay?'), findsOneWidget);

      // Expand first FAQ accordion
      await tester.tap(find.text('How do I cancel my booking or stay?'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'You can review and manage your reservations directly from the Bookings tab. Tap any booking card to view cancellation terms or copy your offline voucher.',
        ),
        findsOneWidget,
      );

      // Tap "START AI CHAT" button to open bottom sheet
      final startChatButton = find.text('START AI CHAT');
      expect(startChatButton, findsOneWidget);
      await tester.tap(startChatButton);
      await tester.pumpAndSettle();

      // Verify AI chat sheet elements
      expect(find.text('Online • Instant Responses'), findsOneWidget);
      expect(find.text('Help with Itinerary'), findsOneWidget);
      expect(find.text('Booking assistance'), findsOneWidget);
      expect(find.text('Emergency contacts'), findsOneWidget);

      // Tap one of the quick suggestions
      final suggestion = find.text('Help with Itinerary');
      expect(suggestion, findsOneWidget);
      await tester.tap(suggestion);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify prompt is in messages
      expect(find.text('Help with Itinerary'), findsWidgets);
    });
  });

  group('DigitalPassportPage Widget Tests', () {
    testWidgets('Renders digital passport statistics and empty state notice', (
      tester,
    ) async {
      const mockStats = PassportStatsModel(
        totalXP: 1850,
        statesVisited: ['Rajasthan', 'Kerala', 'Goa'],
        totalStamps: 7,
        level: 4,
      );

      final mockStamps = [
        const PassportStampModel(
          id: 'stamp_1',
          name: 'Amber Fort',
          state: 'Rajasthan',
          location: 'Reached Amer hill checkpoint at sunrise',
          xpEarned: 150,
        ),
      ];

      final mockTrips = [
        TripItineraryModel.fromMap('trip_1', {
          'destId': 'jaipur',
          'destName': 'Royal Jaipur Heritage',
          'uuid': 'trip_1',
          'form': {'startDate': '2026-11-20', 'days': 3},
          'generatedData': {
            'title': 'Royal Jaipur Heritage',
            'dayPlans': [
              {
                'day': 1,
                'theme': 'Forts',
                'activities': [
                  {
                    'title': 'Amber Fort',
                    'time': '09:00 AM',
                    'location': 'Amer',
                  },
                ],
              },
            ],
          },
        }),
      ];

      final mockSavedPlaces = [
        const SavedPlaceModel(
          id: 'place_city_palace',
          name: 'City Palace Jaipur',
          type: 'Heritage Site',
          location: 'Tulsi Marg, Gangori Bazaar, Jaipur',
        ),
      ];

      await tester.pumpWidget(
        _buildTestableWidget(
          child: const DigitalPassportPage(),
          overrides: [
            passportStatsStreamProvider.overrideWith(
              (ref) => Stream.value(mockStats),
            ),
            passportStampsStreamProvider.overrideWith(
              (ref) => Stream.value(mockStamps),
            ),
            userTripsStreamProvider.overrideWith(
              (ref) => Stream.value(mockTrips),
            ),
            safeSavedPlacesProvider.overrideWithValue(mockSavedPlaces),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify Passport Banner & Stats
      expect(find.text('NAVIIGO TRAVEL ARCHIVE'), findsOneWidget);
      expect(find.text('Your Living Journey Record'), findsOneWidget);
      expect(find.text('JOURNEYS'), findsOneWidget);
      expect(find.text('MOMENTS'), findsOneWidget);
      expect(find.text('SAVED PLACES'), findsNWidgets(2));

      // Verify Upcoming Journey
      expect(find.text('UPCOMING JOURNEYS'), findsOneWidget);
      expect(find.text('Royal Jaipur Heritage'), findsOneWidget);

      // Verify Saved Places
      expect(find.text('City Palace Jaipur'), findsOneWidget);

      // Verify Moments & Stamps
      expect(find.text('MOMENTS & STAMPS'), findsOneWidget);
      expect(find.text('Amber Fort, Rajasthan'), findsOneWidget);
      expect(
        find.text('Reached Amer hill checkpoint at sunrise'),
        findsOneWidget,
      );
    });
  });

  group('BookingsPage Widget Tests', () {
    final List<BookingModel> mockBookings = [
      BookingModel(
        id: 'bkg_1',
        type: 'flight',
        providerName: 'Air India Express',
        providerCode: 'AI-802',
        from: 'DEL',
        to: 'JAI',
        date: '2026-11-20',
        pnr: 'AI-99482',
        status: 'confirmed',
        travelers: 2,
        totalPrice: 4500,
        createdAt: DateTime(2026, 9, 10),
      ),
      BookingModel(
        id: 'bkg_2',
        type: 'rail',
        providerName: 'Vande Bharat Express',
        providerCode: 'VB-201',
        from: 'NDLS',
        to: 'BSB',
        date: '2026-12-05',
        pnr: 'PNR-773829',
        status: 'confirmed',
        travelers: 1,
        totalPrice: 1850,
        createdAt: DateTime(2026, 9, 11),
      ),
    ];

    testWidgets('Renders active bookings and opens voucher details sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const BookingsPage(),
          overrides: [
            bookingsStreamProvider.overrideWith(
              (ref) => Stream.value(mockBookings),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header and List Items
      expect(find.text('BOOKINGS & VOUCHERS'), findsOneWidget);
      expect(find.text('Air India Express'), findsOneWidget);
      expect(find.text('AI-802'), findsOneWidget);
      expect(find.text('DEL → JAI'), findsOneWidget);
      expect(find.text('AI-99482'), findsOneWidget);
      expect(find.text('Vande Bharat Express'), findsOneWidget);
      expect(find.text('NDLS → BSB'), findsOneWidget);

      // Tap on the first booking card to open voucher bottom sheet
      await tester.tap(find.text('Air India Express'));
      await tester.pumpAndSettle();

      // Verify Voucher Bottom Sheet
      expect(find.text('BOOKING VOUCHER'), findsOneWidget);
      expect(find.text('Leg'), findsOneWidget);
      expect(find.text('DEL to JAI'), findsOneWidget);
      expect(find.text('Travel Date'), findsOneWidget);
      expect(find.text('2026-11-20'), findsOneWidget);
      expect(find.text('PNR / Ref'), findsOneWidget);
      expect(find.text('AI-99482'), findsWidgets);
      expect(find.text('SHARE / OFFLINE VOUCHER'), findsOneWidget);

      // Tap the share / offline voucher button
      await tester.tap(find.text('SHARE / OFFLINE VOUCHER'));
      await tester.pumpAndSettle();
    });

    testWidgets('Renders empty bookings state and navigation CTA', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const BookingsPage(),
          overrides: [
            bookingsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Active Bookings'), findsOneWidget);
      expect(find.text('SEARCH TRANSIT & STAYS'), findsOneWidget);
    });
  });

  group('SavedPlacesPage Widget Tests', () {
    final mockSavedPlaces = [
      const SavedPlaceModel(
        id: 'place_amer_fort',
        name: 'Amber Fort',
        type: 'Monument',
        location: 'Amer, Jaipur, Rajasthan',
        image: 'https://images.unsplash.com/photo-1599661046289-e31897846e41',
      ),
      const SavedPlaceModel(
        id: 'place_meenakshi',
        name: 'Meenakshi Temple',
        type: 'Heritage Temple',
        location: 'Madurai, Tamil Nadu',
      ),
    ];

    testWidgets(
      'Renders saved places list with image fallback and bookmark details',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const SavedPlacesPage(),
            overrides: [
              savedPlacesStreamProvider.overrideWith(
                (ref) => Stream.value(mockSavedPlaces),
              ),
              currentUserProvider.overrideWithValue(null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Verify Title & Place Items
        expect(find.text('Saved Places'), findsOneWidget);
        expect(find.text('Amber Fort'), findsOneWidget);
        expect(find.text('Amer, Jaipur, Rajasthan'), findsOneWidget);
        expect(find.text('Meenakshi Temple'), findsOneWidget);
        expect(find.text('Madurai, Tamil Nadu'), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_remove_rounded), findsNWidgets(2));
      },
    );

    testWidgets('Renders empty state with Explore Places button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const SavedPlacesPage(),
          overrides: [
            savedPlacesStreamProvider.overrideWith((ref) => Stream.value([])),
            currentUserProvider.overrideWithValue(null),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No saved places yet'), findsOneWidget);
      expect(find.text('Explore Places'), findsOneWidget);
    });
  });
}
