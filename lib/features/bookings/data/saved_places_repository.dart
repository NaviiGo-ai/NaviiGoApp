import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/firebase_client.dart';
import '../domain/models/saved_place_model.dart';

class SavedPlacesRepository {
  final FirebaseFirestore _firestore;
  final Map<String, Map<String, SavedPlaceModel>> _confirmedByUid = {};
  final Map<String, Set<String>> _pendingWritesByUid = {};

  SavedPlacesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseClient.firestore;

  Stream<List<SavedPlaceModel>> getSavedPlacesStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bucketList')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final previous = _confirmedByUid[uid] ?? const {};
          final pendingWrites = _pendingWritesByUid[uid] ?? const {};
          final itemsById = <String, SavedPlaceModel>{};

          for (final doc in snapshot.docs) {
            if (doc.metadata.hasPendingWrites) {
              final confirmed = previous[doc.id];
              if (confirmed != null) itemsById[doc.id] = confirmed;
              continue;
            }
            itemsById[doc.id] = SavedPlaceModel.fromFirestore(doc);
          }

          // Firestore can omit a locally deleted document from the snapshot
          // before the delete is acknowledged. Retain its last confirmed
          // value until the write future settles.
          for (final id in pendingWrites) {
            final confirmed = previous[id];
            if (confirmed != null) itemsById[id] = confirmed;
          }

          _confirmedByUid[uid] = itemsById;
          final items = itemsById.values.toList();
          items.sort((a, b) {
            final timeA = a.createdAt ?? DateTime(2000);
            final timeB = b.createdAt ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });
          return items;
        });
  }

  Future<bool> toggleSavedPlace(String uid, SavedPlaceModel place) async {
    try {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('bucketList')
          .doc(place.id);

      final snap = await ref.get();
      if (snap.exists) {
        await setSavedPlace(uid, place, false);
      } else {
        await setSavedPlace(uid, place, true);
      }
      return true;
    } catch (e) {
      debugPrint('[SavedPlacesRepository] toggle error: $e');
      return false;
    }
  }

  /// Idempotent desired state. UI waits for server acknowledgement; no
  /// optimistic Firestore snapshot is allowed to claim that a save succeeded.
  Future<void> setSavedPlace(String uid, SavedPlaceModel place, bool saved) {
    if (uid.isEmpty || place.id.isEmpty) {
      throw ArgumentError('Missing owner or place');
    }
    final doc = _firestore
        .collection('users')
        .doc(uid)
        .collection('bucketList')
        .doc(place.id);
    final pendingWrites = _pendingWritesByUid.putIfAbsent(uid, () => {});
    pendingWrites.add(place.id);
    final write = saved
        ? doc.set({...place.toMap(), 'createdAt': FieldValue.serverTimestamp()})
        : doc.delete();
    return write.whenComplete(() {
      pendingWrites.remove(place.id);
      if (pendingWrites.isEmpty) _pendingWritesByUid.remove(uid);
    });
  }

  Future<bool> isPlaceSaved(String uid, String placeId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bucketList')
          .doc(placeId)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }
}
