import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/cache/hive_service.dart';
import 'core/network/firebase_client.dart';
import 'seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Cache (Hive)
  await HiveService.init();

  // Initialize Firebase
  await FirebaseClient.init();

  // UNCOMMENT THE LINE BELOW AND RESTART THE APP TO SEED YOUR FIRESTORE!
  // await seedDatabase();

  runApp(
    const ProviderScope(
      child: NaviiGoApp(),
    ),
  );
}
