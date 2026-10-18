import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naviigo_app/core/auth/auth_provider.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/core/network/api_provider.dart';
import 'package:naviigo_app/core/theme/app_theme.dart';
import 'package:naviigo_app/features/more/presentation/pages/help_support_page.dart';

class TestUser extends Fake implements User {
  TestUser(this.uid);
  @override
  final String uid;
}

void main() {
  Future<ProviderContainer> open(WidgetTester tester, MockClient client) async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(TestUser('A')),
        apiClientProvider.overrideWithValue(
          ApiClient(httpClient: client, baseUrl: 'https://example.com'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const HelpSupportPage())],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('START AI CHAT'));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'support awaits the real reply, sends bounded history and blocks repeated requests',
    (tester) async {
      final reply = Completer<http.Response>();
      final requests = <http.Request>[];
      await open(
        tester,
        MockClient((request) {
          requests.add(request);
          return reply.future;
        }),
      );
      await tester.enterText(
        find.byType(TextField),
        'What should I confirm before visiting Ujjain?',
      );
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/api/chat/');
      expect(requests.single.headers.containsKey('authorization'), isFalse);
      expect(jsonDecode(requests.single.body)['message'], contains('Ujjain'));
      expect(find.text('Requesting AI guidance…'), findsOneWidget);
      await tester.tap(find.byTooltip('Send message'));
      expect(requests, hasLength(1));
      reply.complete(
        http.Response(
          jsonEncode({
            'reply':
                'Confirm current visiting arrangements with the official temple source.',
            'action': null,
          }),
          200,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Confirm current visiting arrangements with the official temple source.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('team is monitoring'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed reply can retry without duplicating the user message', (
    tester,
  ) async {
    var calls = 0;
    await open(
      tester,
      MockClient((request) async {
        calls++;
        return calls == 1
            ? http.Response('{}', 503)
            : http.Response('{"reply":"Live guidance"}', 200);
      }),
    );
    await tester.enterText(find.byType(TextField), 'Help with my journey');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No support request has been filed.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry AI reply'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Help with my journey'), findsOneWidget);
    expect(find.text('Live guidance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'account change clears conversation and drops a late old-account reply',
    (tester) async {
      final response = Completer<http.Response>();
      final container = await open(tester, MockClient((_) => response.future));
      await tester.enterText(find.byType(TextField), 'Account A message');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      container.updateOverrides([
        currentUserProvider.overrideWithValue(TestUser('B')),
        apiClientProvider.overrideWithValue(container.read(apiClientProvider)),
      ]);
      await tester.pump();
      response.complete(http.Response('{"reply":"Account A reply"}', 200));
      await tester.pumpAndSettle();
      expect(find.text('Account A message'), findsNothing);
      expect(find.text('Account A reply'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('support stays readable at phone width and with the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await open(
      tester,
      MockClient((_) async => http.Response('{"reply":"Guidance"}', 200)),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close AI guidance'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Human pilot support hours are still being confirmed.',
      ),
      findsOneWidget,
    );
  });
}
