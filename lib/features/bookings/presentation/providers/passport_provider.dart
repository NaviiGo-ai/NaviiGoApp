import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../data/passport_repository.dart';
import '../../domain/models/passport_model.dart';

final passportRepositoryProvider = Provider<PassportRepository>((ref) {
  return PassportRepository();
});

final passportStatsStreamProvider = StreamProvider<PassportStatsModel>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const PassportStatsModel());
  final repo = ref.watch(passportRepositoryProvider);
  return repo.getPassportStatsStream(user.uid);
});

final passportStampsStreamProvider = StreamProvider<List<PassportStampModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(passportRepositoryProvider);
  return repo.getPassportStampsStream(user.uid);
});
