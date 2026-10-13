import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/core/network/api_exceptions.dart';

Future<dynamic> responseWith(int status, Map<String, dynamic> body) async {
  final transport = MockClient(
    (_) async => http.Response(jsonEncode(body), status),
  );
  final client = ApiClient(
    httpClient: transport,
    baseUrl: 'https://example.test',
  );
  try {
    return await client.post(
      '/api/itinerary/replan/accept',
      requiresAuth: false,
    );
  } finally {
    transport.close();
  }
}

void main() {
  test(
    'canonical backend conflict retains code, message and structured details',
    () async {
      await expectLater(
        responseWith(409, {
          'error': {
            'code': 'IDEMPOTENCY_CONFLICT',
            'message': 'Operation used for another acceptance.',
            'details': {'baseRevisionId': 'rev_0'},
          },
        }),
        throwsA(
          isA<ConflictException>()
              .having(
                (error) => error.conflictCode,
                'code',
                'IDEMPOTENCY_CONFLICT',
              )
              .having(
                (error) => error.message,
                'message',
                'Operation used for another acceptance.',
              )
              .having((error) => error.details?['details'], 'details', {
                'baseRevisionId': 'rev_0',
              }),
        ),
      );
    },
  );
  test('legacy detail conflict remains supported', () async {
    await expectLater(
      responseWith(409, {
        'detail': {
          'code': 'STALE_PROPOSAL',
          'message': 'Refresh the itinerary.',
        },
      }),
      throwsA(
        isA<ConflictException>()
            .having((error) => error.conflictCode, 'code', 'STALE_PROPOSAL')
            .having(
              (error) => error.message,
              'message',
              'Refresh the itinerary.',
            ),
      ),
    );
  });
  test('canonical validation error has a readable message', () async {
    await expectLater(
      responseWith(422, {
        'error': {
          'code': 'REPLAN_VALIDATION_ERROR',
          'message': 'Unsupported replan reason.',
        },
      }),
      throwsA(
        isA<UnprocessableEntityException>().having(
          (error) => error.message,
          'message',
          'Unsupported replan reason.',
        ),
      ),
    );
  });
  test('canonical forbidden error has a readable message', () async {
    await expectLater(
      responseWith(403, {
        'error': {'code': 'FORBIDDEN', 'message': 'Access denied.'},
      }),
      throwsA(
        isA<ForbiddenException>().having(
          (error) => error.message,
          'message',
          'Access denied.',
        ),
      ),
    );
  });
  test('canonical provider error has a readable message', () async {
    await expectLater(
      responseWith(503, {
        'error': {
          'code': 'PERSISTENCE_UNAVAILABLE',
          'message': 'Saving is temporarily unavailable.',
        },
      }),
      throwsA(
        isA<ServerException>().having(
          (error) => error.message,
          'message',
          'Saving is temporarily unavailable.',
        ),
      ),
    );
  });
}
