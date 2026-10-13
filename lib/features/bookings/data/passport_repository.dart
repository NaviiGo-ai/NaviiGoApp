import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/network/firebase_client.dart';
import '../domain/models/passport_model.dart';

enum PassportAwardResult { awarded, alreadyAwarded }

class PassportAwardException implements Exception {
  final String message;

  const PassportAwardException(this.message);

  @override
  String toString() => message;
}

class PassportRepository {
  final FirebaseFirestore _firestore;
  final String? Function() _currentUserUid;

  PassportRepository({
    FirebaseFirestore? firestore,
    String? Function()? currentUserUid,
  }) : _firestore = firestore ?? FirebaseClient.firestore,
       _currentUserUid =
           currentUserUid ?? (() => FirebaseClient.auth.currentUser?.uid);

  /// Stable owner-scoped award key for retrying a user action. The owner path
  /// supplies account isolation; the trip and exact note make a repeated save
  /// resolve to the same Passport entry without depending on wall-clock time.
  static String deterministicAwardKey(String tripId, String note) {
    var hash = 2166136261;
    for (final codeUnit in '$tripId\u0000$note'.codeUnits) {
      hash = ((hash ^ codeUnit) * 16777619) & 0x7fffffff;
    }
    return 'moment_${hash.toRadixString(16)}';
  }

  void _requireUid(String uid) {
    if (uid.trim().isEmpty || _currentUserUid() != uid) {
      throw const PassportAwardException(
        'A signed-in account is required for Passport changes.',
      );
    }
  }

  Stream<PassportStatsModel> getPassportStatsStream(String uid) {
    _requireUid(uid);
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
    _requireUid(uid);
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

  /// Award one Passport entry using the existing owner-scoped paths.
  ///
  /// The entry document ID is the idempotency key. A Firestore transaction
  /// reads that key before writing either the entry or aggregate stats, so a
  /// retry after an ambiguous network result cannot increment XP/stamp counts
  /// twice. Failures are intentionally propagated; callers must not show a
  /// success/verification claim when the owner write was not confirmed.
  Future<PassportAwardResult> addPassportStamp(
    String uid,
    PassportStampModel stamp,
  ) {
    return awardPassportStamp(uid, stamp);
  }

  Future<PassportAwardResult> awardPassportStamp(
    String uid,
    PassportStampModel stamp,
  ) async {
    _requireUid(uid);
    final awardKey = stamp.awardKey?.trim().isNotEmpty == true
        ? stamp.awardKey!.trim()
        : stamp.id.trim();
    if (awardKey.isEmpty || awardKey.contains('/')) {
      throw const PassportAwardException(
        'A stable Passport award identity is required.',
      );
    }
    if (stamp.xpEarned < 0) {
      throw const PassportAwardException('Passport XP cannot be negative.');
    }

    final entries = _firestore
        .collection('users')
        .doc(uid)
        .collection('passport')
        .doc('stamps')
        .collection('entries');
    final entryRef = entries.doc(awardKey);
    final statsRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('passport')
        .doc('stats');

    var result = PassportAwardResult.awarded;
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(entryRef);
      _requireUid(uid);
      if (existing.exists) {
        result = PassportAwardResult.alreadyAwarded;
        return;
      }

      final stored = PassportStampModel(
        id: awardKey,
        name: stamp.name,
        location: stamp.location,
        state: stamp.state,
        icon: stamp.icon,
        type: stamp.type,
        xpEarned: stamp.xpEarned,
        visitedDate: stamp.visitedDate,
        activities: stamp.activities,
        verificationMethod: stamp.verificationMethod,
        isVerified: stamp.isVerified,
        verificationFailure: stamp.verificationFailure,
        awardKey: awardKey,
      );
      transaction.set(entryRef, stored.toFirestore(serverTimestamp: true));
      transaction.set(statsRef, {
        'totalStamps': FieldValue.increment(1),
        'totalXP': FieldValue.increment(stamp.xpEarned),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    _requireUid(uid);
    return result;
  }
}
