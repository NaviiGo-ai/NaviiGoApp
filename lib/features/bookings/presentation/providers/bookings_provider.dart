import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../data/bookings_repository.dart';
import '../../domain/models/booking_model.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository();
});

final bookingsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(bookingsRepositoryProvider);
  return repo.getBookingsStream(user.uid);
});
