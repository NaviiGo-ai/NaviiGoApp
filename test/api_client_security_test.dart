import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/core/network/api_exceptions.dart';

class _Token extends Fake implements IdTokenResult {
  final String owner;
  _Token(this.owner);
  @override
  String get token => 'token-$owner';
  @override
  Map<String, dynamic> get claims => {'sub': owner, 'user_id': owner};
}

class _User extends Fake implements User {
  @override
  final String uid;
  Future<IdTokenResult> Function(bool)? acquireToken;
  _User(this.uid);
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async =>
      acquireToken == null ? _Token(uid) : await acquireToken!(forceRefresh);
}

void main() {
  test(
    'same-origin slash redirect preserves the account and request body',
    () async {
      var requests = 0;
      final api = ApiClient(
        baseUrl: 'https://api.test',
        currentUser: () => _User('A'),
        httpClient: MockClient((request) async {
          requests++;
          expect(request.headers['Authorization'], 'Bearer token-A');
          expect(request.method, 'POST');
          expect(request.body, '{"value":1}');
          if (requests == 1) {
            return http.Response('', 307, headers: {'location': '/private/'});
          }
          expect(request.url.path, '/private/');
          return http.Response('{"ok":true}', 200);
        }),
      );
      expect(await api.post('/private', body: {'value': 1}), {'ok': true});
      expect(requests, 2);
    },
  );

  test(
    'cross-origin method-preserving redirect never receives a token',
    () async {
      var requests = 0;
      final api = ApiClient(
        baseUrl: 'https://api.test',
        currentUser: () => _User('A'),
        httpClient: MockClient((request) async {
          requests++;
          expect(request.url.host, 'api.test');
          return http.Response(
            '',
            307,
            headers: {'location': 'https://untrusted.test'},
          );
        }),
      );
      await expectLater(api.get('/private'), throwsA(isA<ServerException>()));
      expect(requests, 1);
    },
  );

  test('same-origin redirect loops terminate', () async {
    var requests = 0;
    final api = ApiClient(
      baseUrl: 'https://api.test',
      currentUser: () => _User('A'),
      httpClient: MockClient((request) async {
        requests++;
        return http.Response('', 308, headers: {'location': '/loop'});
      }),
    );
    await expectLater(api.get('/loop'), throwsA(isA<ServerException>()));
    expect(requests, 4);
  });

  test(
    'account requests disable redirects before sending credentials',
    () async {
      final api = ApiClient(
        baseUrl: 'https://api.test',
        currentUser: () => _User('A'),
        httpClient: MockClient((request) async {
          expect(request.followRedirects, isFalse);
          return http.Response(
            '',
            302,
            headers: {'location': 'https://untrusted.test'},
          );
        }),
      );
      await expectLater(api.get('/private'), throwsA(isA<ServerException>()));
    },
  );

  test(
    'signed-out private requests fail before contacting the server',
    () async {
      var requests = 0;
      final api = ApiClient(
        baseUrl: 'https://api.test',
        currentUser: () => null,
        httpClient: MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        api.get('/private'),
        throwsA(isA<AuthRequiredException>()),
      );
      expect(requests, 0);
    },
  );

  test(
    'ordinary private requests validate and use the bound account token',
    () async {
      final owner = _User('A');
      final api = ApiClient(
        baseUrl: 'https://api.test',
        currentUser: () => owner,
        httpClient: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer token-A');
          return http.Response('{"owner":"A"}', 200);
        }),
      );
      expect(await api.get('/private'), {'owner': 'A'});
    },
  );

  test(
    'switching accounts during token acquisition prevents the request',
    () async {
      final owner = _User('A');
      User? current = owner;
      var requests = 0;
      owner.acquireToken = (_) async {
        current = _User('B');
        return _Token('B');
      };
      final api = ApiClient(
        baseUrl: 'https://api.test',
        currentUser: () => current,
        httpClient: MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        api.get('/private'),
        throwsA(isA<AuthRequiredException>()),
      );
      expect(requests, 0);
    },
  );

  for (final nextUid in <String?>['B', null]) {
    test(
      'private response is discarded after auth changes to $nextUid',
      () async {
        User? current = _User('A');
        final started = Completer<void>();
        final response = Completer<http.Response>();
        final api = ApiClient(
          baseUrl: 'https://api.test',
          currentUser: () => current,
          httpClient: MockClient((_) {
            started.complete();
            return response.future;
          }),
        );
        final pending = api.get('/private');
        final rejected = expectLater(
          pending,
          throwsA(isA<AuthRequiredException>()),
        );
        await started.future;
        current = nextUid == null ? null : _User(nextUid);
        response.complete(http.Response('{"private":"A only"}', 200));
        await rejected;
      },
    );
  }

  test('401 refresh cannot retry using a newly signed-in account', () async {
    final owner = _User('A');
    User? current = owner;
    var requests = 0;
    owner.acquireToken = (refresh) async {
      if (refresh) current = _User('B');
      return _Token('A');
    };
    final api = ApiClient(
      baseUrl: 'https://api.test',
      currentUser: () => current,
      httpClient: MockClient((_) async {
        requests++;
        return http.Response('{}', 401);
      }),
    );
    await expectLater(
      api.get('/private'),
      throwsA(isA<AuthRequiredException>()),
    );
    expect(requests, 1);
  });

  test('guest endpoints still work without accessing Firebase', () async {
    final api = ApiClient(
      baseUrl: 'https://api.test',
      currentUser: () => throw StateError('Guest endpoints must not read auth'),
      httpClient: MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response('{"public":true}', 200);
      }),
    );
    expect(await api.get('/public', requiresAuth: false), {'public': true});
  });
}
