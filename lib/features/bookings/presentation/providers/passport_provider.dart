import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/passport_repository.dart';
import '../../domain/models/passport_model.dart';

final passportRepositoryProvider = Provider<PassportRepository>((ref) {
  return PassportRepository();
});

// Owner-keyed streams keep previous account data out of a new account's load.
final passportStatsStreamProvider = StreamProvider.autoDispose
    .family<PassportStatsModel, String?>((ref, uid) {
      if (uid == null) return Stream.value(const PassportStatsModel());
      return ref.watch(passportRepositoryProvider).getPassportStatsStream(uid);
    });

final passportStampsStreamProvider = StreamProvider.autoDispose
    .family<List<PassportStampModel>, String?>((ref, uid) {
      if (uid == null) return Stream.value([]);
      return ref.watch(passportRepositoryProvider).getPassportStampsStream(uid);
    });
