import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';

Future<void> signOutFrom(BuildContext context, WidgetRef ref) async {
  if (ref.read(authControllerProvider).status == AuthStatus.loading) return;
  final success = await ref.read(authControllerProvider.notifier).signOut();
  if (!context.mounted) return;
  if (success) {
    context.go('/login');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not sign out. Please try again.')),
    );
  }
}
