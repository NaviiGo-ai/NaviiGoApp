import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:naviigo_app/core/auth/auth_actions.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/core/auth/auth_repository.dart';
import 'package:naviigo_app/core/router/entry_guard.dart';
import 'package:naviigo_app/core/router/app_router.dart';
import 'package:naviigo_app/core/theme/app_theme.dart';
import 'package:naviigo_app/features/auth/presentation/pages/login_page.dart';
import 'package:naviigo_app/features/auth/presentation/pages/onboarding_wizard_page.dart';
import 'package:naviigo_app/features/auth/presentation/pages/vibe_match_page.dart';
import 'package:naviigo_app/features/profile/data/user_repository.dart';
import 'package:naviigo_app/features/profile/domain/models/user_preferences_model.dart';
import 'package:naviigo_app/features/profile/presentation/providers/user_provider.dart';

class _User extends Fake implements User {
  @override
  final String uid;
  _User([this.uid = 'traveller']);
}

class _Auth extends Fake implements AuthRepository {
  Object? failure;
  String? submittedPassword;
  final signedOut = Completer<void>();
  @override
  User? get currentUser => null;
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    submittedPassword = password;
    throw failure ?? StateError('private/server/details');
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    throw failure ?? StateError('private/server/details');
  }

  @override
  Future<void> signOut() async {
    if (failure != null) throw failure!;
    await signedOut.future;
  }
}

class _Preferences extends Fake implements UserRepository {
  UserPreferencesModel value;
  _Preferences(this.value);
  Completer<void>? acknowledgement;
  Object? failure;
  int writes = 0;
  final userStreams = <String, Stream<UserPreferencesModel>>{};
  @override
  Stream<UserPreferencesModel> getUserPreferencesStream(String uid) =>
      userStreams[uid] ?? Stream.value(value);
  @override
  Future<void> updateUserPreferences(
    String uid,
    UserPreferencesModel prefs, {
    bool includeEmptyLists = false,
  }) async {
    writes++;
    if (failure != null) throw failure!;
    if (acknowledgement != null) await acknowledgement!.future;
    value = prefs;
  }

  @override
  Future<void> completeOnboarding(String uid, UserPreferencesModel prefs) =>
      updateUserPreferences(uid, prefs.copyWith(onboardingCompleted: true));
}

Future<void> _entry(
  WidgetTester tester,
  Widget page,
  _Preferences repository, {
  double scale = 1,
  bool reduced = false,
  _Auth? auth,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_User()),
        userRepositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(auth ?? _Auth()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced,
          ),
          child: child!,
        ),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  group('Entry guard', () {
    test(
      'changing accounts never reuses previous completion, even on a read error',
      () async {
        final authEvents = StreamController<User?>();
        final otherPreferences = StreamController<UserPreferencesModel>();
        final repo = _Preferences(
          const UserPreferencesModel(onboardingCompleted: true),
        );
        repo.userStreams['other'] = otherPreferences.stream;
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((_) => authEvents.stream),
            authRepositoryProvider.overrideWithValue(_Auth()),
            userRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(authEvents.close);
        addTearDown(otherPreferences.close);
        final subscription = container.listen(
          entryStatusProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);
        authEvents.add(_User());
        await container.read(authStateProvider.future);
        await container.read(userPreferencesStreamProvider.future);
        expect(container.read(entryStatusProvider), EntryStatus.complete);
        authEvents.add(_User('other'));
        await Future<void>.delayed(Duration.zero);
        expect(container.read(entryStatusProvider), EntryStatus.loading);
        otherPreferences.addError(Exception('offline'));
        await Future<void>.delayed(Duration.zero);
        expect(container.read(entryStatusProvider), EntryStatus.error);
        otherPreferences.add(const UserPreferencesModel());
        await Future<void>.delayed(Duration.zero);
        expect(container.read(entryStatusProvider), EntryStatus.incomplete);
      },
    );

    for (final (status, expected) in [
      (EntryStatus.signedOut, '/login'),
      (EntryStatus.incomplete, '/onboarding'),
      (EntryStatus.complete, '/home'),
      (EntryStatus.loading, null),
      (EntryStatus.error, null),
    ]) {
      test('$status at splash resolves to $expected', () {
        expect(entryRedirect(Uri.parse('/'), status), expected);
      });
    }

    test('all entry states converge without redirect loops', () {
      for (final status in EntryStatus.values) {
        for (final path in [
          '/',
          '/login',
          '/onboarding',
          '/vibe-match',
          '/home',
          '/destination/jaipur?day=2',
        ]) {
          final first = entryRedirect(Uri.parse(path), status);
          if (first != null) {
            expect(
              entryRedirect(Uri.parse(first), status),
              isNull,
              reason: '$status $path -> $first',
            );
          }
        }
      }
    });

    test('authenticated deep link survives login and onboarding', () {
      var location = Uri.parse('/destination/jaipur?day=2');
      location = Uri.parse(entryRedirect(location, EntryStatus.loading)!);
      location = Uri.parse(entryRedirect(location, EntryStatus.signedOut)!);
      expect(location.path, '/login');
      location = Uri.parse(entryRedirect(location, EntryStatus.incomplete)!);
      expect(location.path, '/onboarding');
      location = Uri.parse(entryLocation('/vibe-match', location));
      expect(
        entryRedirect(location, EntryStatus.complete),
        '/destination/jaipur?day=2',
      );
    });

    test('external and recursive return destinations are rejected', () {
      for (final next in [
        'https://example.com',
        '//example.com',
        '/login',
        '/onboarding',
        '/\\example.com',
      ]) {
        final uri = Uri(path: '/login', queryParameters: {'next': next});
        expect(entryRedirect(uri, EntryStatus.complete), '/home');
      }
    });

    test('signed-out deep links cannot bypass either gate', () {
      for (final path in ['/home', '/vibe-match', '/profile']) {
        expect(
          Uri.parse(
            entryRedirect(Uri.parse(path), EntryStatus.signedOut)!,
          ).path,
          '/login',
        );
      }
    });

    test(
      'legacy preferences are incomplete, regardless of populated fields',
      () {
        final preferences = UserPreferencesModel.fromMap({
          'travelStyle': 'luxury',
          'preferredGroup': 'family',
          'interests': ['culture'],
        });
        expect(preferences.onboardingCompleted, isFalse);
        expect(preferences.adaptiveAppearanceEnabled, isTrue);
      },
    );

    test(
      'confirmed cached state remains usable during refresh errors',
      () async {
        final events = StreamController<UserPreferencesModel>();
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((_) => Stream.value(_User())),
            userPreferencesStreamProvider.overrideWith((_) => events.stream),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(events.close);
        await container.read(authStateProvider.future);
        events.add(
          const UserPreferencesModel(
            onboardingCompleted: true,
            sourceUserId: 'traveller',
          ),
        );
        await container.read(userPreferencesStreamProvider.future);
        events.addError(Exception('offline'));
        await Future<void>.delayed(Duration.zero);
        expect(container.read(entryStatusProvider), EntryStatus.complete);
      },
    );

    test(
      'preferences failure without usable data is an error, not completion',
      () async {
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((_) => Stream.value(_User())),
            userPreferencesStreamProvider.overrideWith(
              (_) => Stream.error(Exception('offline')),
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(authStateProvider.future);
        await expectLater(
          container.read(userPreferencesStreamProvider.future),
          throwsException,
        );
        expect(container.read(entryStatusProvider), EntryStatus.error);
      },
    );

    test(
      'router instance is stable across auth changes and logout is signed out',
      () async {
        final events = StreamController<User?>();
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((_) => events.stream),
            authRepositoryProvider.overrideWithValue(_Auth()),
            userPreferencesStreamProvider.overrideWith(
              (_) => Stream.value(
                const UserPreferencesModel(
                  onboardingCompleted: true,
                  sourceUserId: 'traveller',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(events.close);
        final router = container.read(appRouterProvider);
        events.add(_User());
        await container.read(authStateProvider.future);
        await container.read(userPreferencesStreamProvider.future);
        expect(container.read(entryStatusProvider), EntryStatus.complete);
        events.add(null);
        await Future<void>.delayed(Duration.zero);
        expect(container.read(currentUserProvider), isNull);
        expect(container.read(entryStatusProvider), EntryStatus.signedOut);
        expect(container.read(appRouterProvider), same(router));
      },
    );
  });

  group('Auth failures and logout', () {
    test('Firebase and unknown exceptions use readable safe errors', () async {
      final repo = _Auth();
      final controller = AuthController(repo);
      addTearDown(controller.dispose);
      expect(await controller.signIn('a@b.com', 'secret'), isFalse);
      expect(
        controller.state.errorMessage,
        'Could not sign in. Please try again.',
      );
      repo.failure = FirebaseAuthException(
        code: 'network-request-failed',
        message: 'internal host/token',
      );
      expect(await controller.signIn('a@b.com', 'secret'), isFalse);
      expect(
        controller.state.errorMessage,
        'Check your connection and try again.',
      );
      repo.failure = FirebaseAuthException(
        code: 'unknown',
        message: 'internal host/token',
      );
      expect(
        await controller.register('a@b.com', 'secret', 'Traveller'),
        isFalse,
      );
      expect(controller.state.errorMessage, isNot(contains('internal')));
    });

    testWidgets(
      'logout failure stays in shell; confirmed sign-out routes to login',
      (tester) async {
        final auth = _Auth()..failure = Exception('secret');
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => Consumer(
                builder: (context, ref, _) => Scaffold(
                  body: TextButton(
                    onPressed: () => signOutFrom(context, ref),
                    child: const Text('Logout'),
                  ),
                ),
              ),
            ),
            GoRoute(path: '/login', builder: (_, __) => const Text('LOGIN')),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(auth)],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/home');
        expect(
          find.text('Could not sign out. Please try again.'),
          findsOneWidget,
        );
        auth.failure = null;
        await tester.tap(find.text('Logout'));
        await tester.pump();
        expect(router.routeInformationProvider.value.uri.path, '/home');
        auth.signedOut.complete();
        await tester.pumpAndSettle();
        expect(find.text('LOGIN'), findsOneWidget);
      },
    );

    testWidgets('password whitespace preserved and errors rendered safely', (
      tester,
    ) async {
      final auth = _Auth();
      await _entry(
        tester,
        const LoginPage(),
        _Preferences(const UserPreferencesModel()),
        auth: auth,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        ' password ',
      );
      await _tap(tester, 'Sign in');
      expect(auth.submittedPassword, ' password ');
      expect(find.text('Could not sign in. Please try again.'), findsOneWidget);
    });
  });

  group('Entry screens', () {
    testWidgets(
      'deep link passes real onboarding and only confirmed completion unlocks it',
      (tester) async {
        final repo = _Preferences(const UserPreferencesModel());
        final authEvents = StreamController<User?>();
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_Auth()),
            authStateProvider.overrideWith((_) => authEvents.stream),
            userRepositoryProvider.overrideWithValue(repo),
          ],
        );
        final refresh = ValueNotifier(EntryStatus.loading);
        final subscription = container.listen(
          entryStatusProvider,
          (_, next) => refresh.value = next,
          fireImmediately: true,
        );
        final router = GoRouter(
          initialLocation: '/destination/jaipur?day=2',
          refreshListenable: refresh,
          redirect: (_, state) => entryRedirect(state.uri, refresh.value),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const Text('LOADING')),
            GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
            GoRoute(
              path: '/onboarding',
              builder: (_, __) => const OnboardingWizardPage(),
            ),
            GoRoute(
              path: '/vibe-match',
              builder: (_, __) => const VibeMatchPage(),
            ),
            GoRoute(
              path: '/destination/:id',
              builder: (_, __) => const Text('AUTHENTICATED DESTINATION'),
            ),
          ],
        );
        addTearDown(() {
          router.dispose();
          subscription.close();
          refresh.dispose();
          container.dispose();
        });
        addTearDown(authEvents.close);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: AppTheme.lightTheme(),
              routerConfig: router,
            ),
          ),
        );
        authEvents.add(null);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/login');
        authEvents.add(_User());
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/onboarding');
        await _tap(tester, 'Continue');
        await _tap(tester, 'Comfort · Mid-range');
        await _tap(tester, 'Continue');
        await _tap(tester, 'Solo');
        await _tap(tester, 'Continue');
        await _tap(tester, 'Food');
        await _tap(tester, 'Continue');
        await _tap(tester, 'Skip this step');
        await _tap(tester, 'Skip this step');
        await _tap(tester, 'Save & explore your vibe');
        expect(repo.value.onboardingCompleted, isFalse);
        expect(repo.value.interests, ['food']);
        expect(router.routeInformationProvider.value.uri.path, '/vibe-match');
        repo.acknowledgement = Completer<void>();
        await tester.ensureVisible(find.text('Finish & start exploring'));
        await tester.tap(find.text('Finish & start exploring'));
        await tester.pump();
        expect(router.routeInformationProvider.value.uri.path, '/vibe-match');
        repo.acknowledgement!.complete();
        await tester.pumpAndSettle();
        expect(repo.value.onboardingCompleted, isTrue);
        expect(
          router.routeInformationProvider.value.uri.toString(),
          '/destination/jaipur?day=2',
        );
        expect(find.text('AUTHENTICATED DESTINATION'), findsOneWidget);
      },
    );

    for (final (name, page) in <(String, Widget)>[
      ('login', const LoginPage()),
      ('onboarding', const OnboardingWizardPage()),
      ('vibe', const VibeMatchPage()),
    ]) {
      testWidgets(
        '$name supports narrow viewport, large text, reduced motion',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _entry(
            tester,
            page,
            _Preferences(const UserPreferencesModel()),
            scale: 2.5,
            reduced: true,
          );
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -600),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'vibe selection is explicit, reversible, and does not write before finish',
      (tester) async {
        final repo = _Preferences(
          const UserPreferencesModel(interests: ['food']),
        );
        await _entry(tester, const VibeMatchPage(), repo);
        await _tap(tester, 'Add Culture interest');
        expect(find.widgetWithText(InputChip, 'culture'), findsOneWidget);
        expect(find.widgetWithText(InputChip, 'food'), findsOneWidget);
        await _tap(tester, 'Undo last change');
        expect(find.widgetWithText(InputChip, 'culture'), findsNothing);
        expect(repo.writes, 0);
      },
    );

    testWidgets('vibe completion failure has retry and no fake completion', (
      tester,
    ) async {
      final repo = _Preferences(const UserPreferencesModel())
        ..failure = Exception('internal');
      await _entry(tester, const VibeMatchPage(), repo);
      await _tap(tester, 'Finish & start exploring');
      expect(find.text('Retry completion'), findsOneWidget);
      expect(repo.value.onboardingCompleted, isFalse);
      repo.failure = null;
      repo.acknowledgement = Completer<void>();
      await tester.ensureVisible(find.text('Retry completion'));
      await tester.tap(find.text('Retry completion'));
      await tester.pump();
      expect(find.text('Waiting for confirmation…'), findsOneWidget);
      expect(repo.value.onboardingCompleted, isFalse);
      repo.acknowledgement!.complete();
      await tester.pumpAndSettle();
      expect(repo.value.onboardingCompleted, isTrue);
    });

    testWidgets('wizard retains choices and retries failed save before vibe', (
      tester,
    ) async {
      final repo = _Preferences(const UserPreferencesModel())
        ..failure = Exception('offline');
      await _entry(
        tester,
        const OnboardingWizardPage(),
        repo,
        scale: 2,
        reduced: true,
      );
      await _tap(tester, 'Continue');
      await _tap(tester, 'Comfort · Mid-range');
      await _tap(tester, 'Continue');
      await _tap(tester, 'Solo');
      await _tap(tester, 'Continue');
      await _tap(tester, 'Food');
      await _tap(tester, 'Continue');
      await _tap(tester, 'Skip this step');
      await _tap(tester, 'Skip this step');
      await _tap(tester, 'Save & explore your vibe');
      expect(find.text('Retry save'), findsOneWidget);
      expect(repo.value.onboardingCompleted, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
