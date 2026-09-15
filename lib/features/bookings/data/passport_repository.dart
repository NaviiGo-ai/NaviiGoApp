import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/network/firebase_client.dart';
import '../domain/models/passport_model.dart';

class PassportRepository {
  final FirebaseFirestore _firestore;

  PassportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseClient.firestore;

  Stream<PassportStatsModel> getPassportStatsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('passport')
        .doc('stats')
        .snapshots()
        .map(
          (doc) => doc.exists
              ? PassportStatsModel.fromFirestore(doc)
              : const PassportStatsModel(),
        );
  }

  Stream<List<PassportStampModel>> getPassportStampsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('passport')
        .doc('stamps')
        .collection('entries')
        .snapshots()
        .map((snapshot) {
          final stamps = snapshot.docs
              .map((doc) => PassportStampModel.fromFirestore(doc))
              .toList();
          stamps.sort((a, b) {
            final timeA = a.visitedDate ?? DateTime(2000);
            final timeB = b.visitedDate ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });
          return stamps;
        });
  }

  Future<void> addPassportStamp(String uid, PassportStampModel stamp) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('passport')
          .doc('stamps')
          .collection('entries')
          .doc(stamp.id)
          .set({
            'name': stamp.name,
            'location': stamp.location,
            'state': stamp.state,
            'icon': stamp.icon,
            'type': stamp.type,
            'xpEarned': stamp.xpEarned,
            'visitedDate': FieldValue.serverTimestamp(),
            'activities': stamp.activities,
          });

      // Increment stats
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('passport')
          .doc('stats')
          .set({
            'totalStamps': FieldValue.increment(1),
            'totalXP': FieldValue.increment(stamp.xpEarned),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      // Ignored for offline safety
    }
  }
}
