import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/cache/hive_service.dart';
import 'core/network/firebase_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Cache (Hive)
  await HiveService.init();

  // Initialize Firebase
  await FirebaseClient.init();

  // Sign in anonymously to bypass Firestore rules for demo
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint('Anonymous auth disabled in Firebase Console: $e');
  }

  // UNCOMMENT THE LINE BELOW AND RESTART THE APP TO SEED YOUR FIRESTORE!
  // await seedDatabase();

  runApp(
    const ProviderScope(
      child: NaviiGoApp(),
    ),
  );
}
