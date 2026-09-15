import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../data/user_repository.dart';
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
