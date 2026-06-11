import 'dart:io';

void main() async {
  final Map<String, List<String>> structure = {
    'auth': ['login'],
    'dashboard': ['home', 'upcoming_trips', 'ongoing_trips', 'live_tracking', 'analytics'],
    'explore': ['hidden_gems', 'restaurants', 'transportation'],
    'bookings': ['saved_places', 'payment_history', 'digital_passport'],
    'more': ['story_creator', 'settings', 'help_support'],
  };

  for (var entry in structure.entries) {
    final feature = entry.key;
    final pages = entry.value;

    for (var page in pages) {
      final dir = Directory('lib/features/$feature/presentation/pages');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${dir.path}/${page}_page.dart');
      
      // Convert snake_case to PascalCase for the class name
      final className = page.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join('') + 'Page';
      
      final content = '''
import 'package:flutter/material.dart';

class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$className')),
      body: const Center(
        child: Text('Placeholder for $className'),
      ),
    );
  }
}
''';
      await file.writeAsString(content);
      print('Created \${file.path}');
    }
  }
}
