import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/core/network/api_client.dart';
import 'package:naviigo_app/features/trips/data/trip_repository.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Starting Verification...');
  try {
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:8000',
      httpClient: http.Client(),
    );
    final repo = TripRepository(apiClient: client);

    // This is a synthetic call just to test if the API contract is solid
    final trip = await repo.generateItineraryFromBackend(
      destName: 'Jaipur',
      destination: 'jaipur',
      days: 2,
      purpose: 'cultural',
      group: 'solo',
      budget: 15000,
    );

    print('Trip generated successfully: ${trip.id}');
    print('Dest: ${trip.destName}');
    print('Days: ${trip.dayPlans.length}');
    if (trip.dayPlans.isNotEmpty) {
      print('First Activity: ${trip.dayPlans.first.activities.first.title}');
    }
    print('SUCCESS');
  } catch (e) {
    print('FAILED: $e');
  }
}
