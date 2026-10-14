import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/cache/hive_service.dart';
import 'core/network/firebase_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _StartupGate());
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();
  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late Future<void> _startup = _initialize();

  Future<void> _initialize() async {
    await HiveService.init();
    await FirebaseClient.init();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return const ProviderScope(child: NaviiGoApp());
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFFCF8F3),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NaviiGo',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  if (snapshot.hasError) ...[
                    const Text(
                      'Could not open NaviiGo. Check your connection and try again.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() => _startup = _initialize()),
                      child: const Text('Retry'),
                    ),
                  ] else ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Opening your next chapter…'),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
