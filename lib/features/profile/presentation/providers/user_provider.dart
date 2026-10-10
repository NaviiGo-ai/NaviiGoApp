import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../data/user_repository.dart';
import '../../domain/models/user_preferences_model.dart';
import '../../domain/models/user_profile_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final userProfileStreamProvider = StreamProvider<UserProfileModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value(null);
  }
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserProfileStream(currentUser.uid);
});

final userPreferencesStreamProvider = StreamProvider<UserPreferencesModel>((
  ref,
) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value(const UserPreferencesModel());
  }
  final repo = ref.watch(userRepositoryProvider);
  final uid = currentUser.uid;
  return repo
      .getUserPreferencesStream(uid)
      .map((preferences) => preferences.copyWith(sourceUserId: uid));
});

/// The only composition-root selector for adaptive user preferences.
///
/// AsyncValue may retain data while a stream dependency changes. Same-UID
/// cached data remains usable during a refresh; a different UID always gets
/// standard Naviigo defaults.
final safeAdaptivePreferencesProvider = Provider<UserPreferencesModel>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const UserPreferencesModel();

  final preferences = ref.watch(userPreferencesStreamProvider).valueOrNull;
  if (preferences == null || preferences.sourceUserId != uid) {
    return const UserPreferencesModel();
  }
  return preferences;
});
