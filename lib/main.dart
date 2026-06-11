import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/cache/hive_service.dart';
import 'core/network/firebase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Cache (Hive)
  await HiveService.init();

  // Initialize Firebase (Staged for active project configuration setup)
  await FirebaseClient.init();

  runApp(
    const ProviderScope(
      child: NaviiGoApp(),
    ),
  );
}
