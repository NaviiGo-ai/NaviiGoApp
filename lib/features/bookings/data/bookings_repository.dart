import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/network/firebase_client.dart';
import '../domain/models/booking_model.dart';

class BookingsRepository {
  final FirebaseFirestore _firestore;

  BookingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseClient.firestore;

  Stream<List<BookingModel>> getBookingsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bookings')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) {
            final timeA = a.createdAt ?? DateTime(2000);
            final timeB = b.createdAt ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });
          return items;
        });
  }
}
