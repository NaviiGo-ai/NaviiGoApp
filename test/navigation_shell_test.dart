import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:naviigo_app/core/motion/nav_route_transition.dart';
import 'package:naviigo_app/features/navigation/presentation/nav_hub_page.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Guards the navigation shell.
///
/// These exist because the drawer was silently unreachable in production: the
/// shell Scaffold had no `drawer`, every page hard-coded a back-arrow leading,
/// and the one widget that called openDrawer() was dead code. Nothing in the
/// suite noticed — every page rendered fine, you just could not go anywhere.
///
/// Note on assertions: the drawer body is a lazy `ListView`, so only the
/// section headers and items near the top are built at the default 800x600
/// test viewport. Assertions stick to what is genuinely on screen.
/// ─────────────────────────────────────────────────────────────────────────────

/// A page that does nothing but expose the shell's own leading widget, so the
/// test exercises the real mechanism without dragging in Firebase-backed pages.
Widget _probePage(String label) {
  return Scaffold(
    appBar: AppBar(leading: const NavHubLeading()),
    body: Center(child: Text(label)),
  );
}

/// A page long enough to actually scroll, so the shell's chrome coordination
/// has something to listen to.
Widget _scrollablePage() {
  return Scaffold(
    appBar: AppBar(leading: const NavHubLeading()),
    body: ListView.builder(
      itemCount: 60,
      itemBuilder: (_, i) => SizedBox(height: 48, child: Text('row $i')),
    ),
  );
}

GoRouter _router({String initial = '/home'}) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      ShellRoute(
        builder: (context, state, child) => NavHubPage(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => _probePage('HOME PAGE')),
          GoRoute(
            path: '/explore-discover',
            builder: (_, __) => _probePage('EXPLORE PAGE'),
          ),
          GoRoute(path: '/trips', builder: (_, __) => _probePage('TRIPS PAGE')),
          GoRoute(
            path: '/transportation',
            builder: (_, __) => _probePage('TRANSIT PAGE'),
          ),
          GoRoute(
            path: '/digital-passport',
            builder: (_, __) => _probePage('PASSPORT PAGE'),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => _probePage('PROFILE PAGE'),
          ),
          GoRoute(path: '/scrollable', builder: (_, __) => _scrollablePage()),
          GoRoute(
            path: '/upcoming-trips',
            builder: (_, __) => _probePage('UPCOMING PAGE'),
          ),
          GoRoute(
            path: '/destination/:id',
            builder: (_, state) =>
                _probePage('DESTINATION ${state.pathParameters['id']}'),
          ),
          GoRoute(
            path: '/trip-planner',
            builder: (_, __) => _probePage('TRIP PLANNER PAGE'),
          ),
        ],
      ),
    ],
  );
}

Future<void> _pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await tester.pumpAndSettle();
}

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu_rounded));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('repeated profile pushes can pop and leave the profile', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        ShellRoute(
          builder: (_, __, child) => NavHubPage(child: child),
          routes: [
            for (final path in ['/home', '/profile'])
              GoRoute(
                path: path,
                pageBuilder: (_, state) => NavRouteTransition.page(
                  state: state,
                  child: _probePage(path),
                ),
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    router.push('/profile');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    router.pop();
    await tester.pumpAndSettle();
    router.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('/home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('NavHubPage shell', () {
    testWidgets('renders the five bottom-nav roots and no drawer', (
      tester,
    ) async {
      await _pumpShell(tester);

      expect(find.text('HOME PAGE'), findsOneWidget);
      for (final label in ['Home', 'Explore', 'Trips', 'Passport', 'Profile']) {
        expect(find.text(label), findsOneWidget, reason: 'missing tab $label');
      }
      // Closed drawer is not built at all.
      expect(find.byType(Drawer), findsNothing);
    });

    testWidgets('the leading button opens the navigation drawer', (
      tester,
    ) async {
      await _pumpShell(tester);
      await _openDrawer(tester);

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('NaviiGo'), findsOneWidget);

      // Sections and destinations the five bottom-nav roots do not cover.
      expect(find.text('JOURNEYS'), findsOneWidget);
      expect(find.text('Upcoming Journeys'), findsOneWidget);
      expect(find.text('Live Trip Companion'), findsOneWidget);
      expect(find.text('DISCOVER'), findsOneWidget);
      expect(find.text('Hidden Gems'), findsOneWidget);
    });

    testWidgets('a drawer destination navigates and closes the drawer', (
      tester,
    ) async {
      await _pumpShell(tester);
      await _openDrawer(tester);

      await tester.tap(find.text('Upcoming Journeys'));
      await tester.pumpAndSettle();

      expect(find.text('UPCOMING PAGE'), findsOneWidget);
      expect(find.byType(Drawer), findsNothing); // closed behind us
    });

    testWidgets('the bottom bar routes away from the current root', (
      tester,
    ) async {
      await _pumpShell(tester);
      expect(find.text('HOME PAGE'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('HOME PAGE'), findsNothing);
      expect(find.text('PROFILE PAGE'), findsOneWidget);
    });

    testWidgets('the leading degrades to the menu without a GoRouter', (
      tester,
    ) async {
      // Pages are also rendered outside a router (previews, tests). The leading
      // must degrade, not assert — it previously called context.canPop(), which
      // throws "No GoRouter found in context".
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NavHubLeading())),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('child routes inside ShellRoute retain bottom nav items', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: _router(initial: '/destination/jaipur'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DESTINATION jaipur'), findsOneWidget);
      for (final label in ['Home', 'Explore', 'Trips', 'Passport', 'Profile']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets(
      'trip planner route inside ShellRoute retains bottom nav items',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: _router(initial: '/trip-planner'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('TRIP PLANNER PAGE'), findsOneWidget);
        for (final label in [
          'Home',
          'Explore',
          'Trips',
          'Passport',
          'Profile',
        ]) {
          expect(find.text(label), findsOneWidget);
        }
      },
    );
  });

  group('NavHubPage chrome coordination (§4)', () {
    /// A user drag, which is what emits UserScrollNotification.
    Future<void> drag(WidgetTester tester, double dy) async {
      await tester.drag(find.byType(ListView), Offset(0, dy));
      await tester.pumpAndSettle();
    }

    testWidgets('scrolling into the page compacts the bar, scrolling back '
        'restores it', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: _router(initial: '/scrollable'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(NavHubPage)),
      );

      expect(container.read(navChromeCollapseProvider), 0.0, reason: 'at rest');

      await drag(tester, -400);
      expect(
        container.read(navChromeCollapseProvider),
        1.0,
        reason: 'scrolling down should tighten the chrome',
      );
      // The labels are the visible consequence of that.
      final label = tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.text('Home'),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(label.opacity, 0.0);

      await drag(tester, 200);
      expect(
        container.read(navChromeCollapseProvider),
        0.0,
        reason: 'scrolling up should bring the chrome back',
      );
      expect(
        tester
            .widget<AnimatedOpacity>(
              find
                  .ancestor(
                    of: find.text('Home'),
                    matching: find.byType(AnimatedOpacity),
                  )
                  .first,
            )
            .opacity,
        1.0,
      );
    });

    testWidgets('reaching the top restores the chrome even without a '
        'scroll-up gesture', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: _router(initial: '/scrollable'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(NavHubPage)),
      );

      await drag(tester, -400);
      expect(container.read(navChromeCollapseProvider), 1.0);

      // Fling straight back to the top: the gesture direction on the way is
      // still 'reverse' for part of the travel.
      await tester.fling(find.byType(ListView), const Offset(0, 400), 3000);
      await tester.pumpAndSettle();

      expect(container.read(navChromeCollapseProvider), 0.0);
    });

    testWidgets('leaving for another route restores the chrome', (
      tester,
    ) async {
      // The next screen has not been scrolled at all, so carrying a compacted
      // bar into it would be a lie about its position.
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: _router(initial: '/scrollable'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(NavHubPage)),
      );

      await drag(tester, -400);
      expect(container.read(navChromeCollapseProvider), 1.0);

      await _openDrawer(tester);
      await tester.tap(find.text('Upcoming Journeys'));
      await tester.pumpAndSettle();

      expect(find.text('UPCOMING PAGE'), findsOneWidget);
      expect(container.read(navChromeCollapseProvider), 0.0);
    });
  });

  group('Shell accessibility and entry integration', () {
    testWidgets(
      'six roots retain ordering and route correctly at 320px with large text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = _router();
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(2.5)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        double previousX = -1;
        for (final (label, path) in [
          ('Home', '/home'),
          ('Explore', '/explore-discover'),
          ('Transit', '/transportation'),
          ('Trips', '/trips'),
          ('Passport', '/digital-passport'),
          ('Profile', '/profile'),
        ]) {
          final x = tester.getCenter(find.text(label)).dx;
          expect(x, greaterThan(previousX));
          previousX = x;
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, path);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'reduced-motion chrome collapses quickly and retains tab semantics',
      (tester) async {
        final router = _router(initial: '/scrollable');
        addTearDown(router.dispose);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TweenAnimationBuilder<double>>(
                find.byType(TweenAnimationBuilder<double>).first,
              )
              .duration
              .inMilliseconds,
          1,
        );
        for (final label in [
          'Home',
          'Explore',
          'Trips',
          'Passport',
          'Profile',
        ]) {
          expect(find.bySemanticsLabel(label), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );

    testWidgets('keyboard hides bottom chrome without losing the route', (
      tester,
    ) async {
      final router = _router();
      addTearDown(router.dispose);
      final keyboard = ValueNotifier(0.0);
      addTearDown(keyboard.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => ValueListenableBuilder<double>(
              valueListenable: keyboard,
              builder: (_, inset, _) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(viewInsets: EdgeInsets.only(bottom: inset)),
                child: child!,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      keyboard.value = 300;
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
      expect(find.text('HOME PAGE'), findsOneWidget);
      keyboard.value = 0;
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/home');
    });
  });
}
