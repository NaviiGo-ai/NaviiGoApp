import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../../features/profile/presentation/providers/user_provider.dart';

enum EntryStatus { loading, signedOut, incomplete, complete, error }

final entryStatusProvider = Provider<EntryStatus>((ref) {
  final auth = ref.watch(authStateProvider);
  if (!auth.hasValue) {
    return auth.hasError ? EntryStatus.error : EntryStatus.loading;
  }
  if (auth.value == null) return EntryStatus.signedOut;
  final preferences = ref.watch(userPreferencesStreamProvider);
  // A dependency/UID change must not reuse another account's previous value.
  if (preferences.isReloading) return EntryStatus.loading;
  final value = preferences.valueOrNull;
  if (value != null && value.sourceUserId == auth.value!.uid) {
    return value.onboardingCompleted
        ? EntryStatus.complete
        : EntryStatus.incomplete;
  }
  return preferences.hasError ? EntryStatus.error : EntryStatus.loading;
});

const _entryPaths = {'/', '/login', '/onboarding', '/vibe-match'};

/// Only an internal, non-entry location can be resumed after the gate.
String? _safeDestination(String? raw) {
  if (raw == null ||
      !raw.startsWith('/') ||
      raw.startsWith('//') ||
      raw.contains('\\')) {
    return null;
  }
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      _entryPaths.contains(uri.path)) {
    return null;
  }
  return uri.toString();
}

String entryLocation(String path, Uri current) {
  final destination = _entryPaths.contains(current.path)
      ? _safeDestination(current.queryParameters['next'])
      : _safeDestination(current.toString());
  return Uri(
    path: path,
    queryParameters: destination == null ? null : {'next': destination},
  ).toString();
}

/// Pure, idempotent guard shared by the production router and routing tests.
String? entryRedirect(Uri location, EntryStatus status) {
  final path = location.path;
  switch (status) {
    case EntryStatus.loading:
    case EntryStatus.error:
      return path == '/' ? null : entryLocation('/', location);
    case EntryStatus.signedOut:
      return path == '/login' ? null : entryLocation('/login', location);
    case EntryStatus.incomplete:
      if (path == '/onboarding' || path == '/vibe-match') return null;
      return entryLocation('/onboarding', location);
    case EntryStatus.complete:
      if (!_entryPaths.contains(path)) return null;
      return _safeDestination(location.queryParameters['next']) ?? '/home';
  }
}
