import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/firebase_client.dart';
import '../domain/models/saved_place_model.dart';
import '../../analytics/data/analytics_repository.dart';

class SavedPlacesRepository {
  final FirebaseFirestore _firestore;
  final AnalyticsRepository? _analyticsRepo;

  SavedPlacesRepository({
    FirebaseFirestore? firestore,
    AnalyticsRepository? analyticsRepo,
  }) : _firestore = firestore ?? FirebaseClient.firestore,
       _analyticsRepo = analyticsRepo;

  Stream<List<SavedPlaceModel>> getSavedPlacesStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bucketList')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => SavedPlaceModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) {
            final timeA = a.createdAt ?? DateTime(2000);
            final timeB = b.createdAt ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });
          return items;
        });
  }

  Future<void> toggleSavedPlace(String uid, SavedPlaceModel place) async {
    try {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('bucketList')
          .doc(place.id);

      final snap = await ref.get();
      if (snap.exists) {
        await ref.delete();
        _analyticsRepo?.logEvent(
          eventType: 'PLACE_UNSAVED',
          placeId: place.id,
          destinationId: place.name,
        );
      } else {
        await ref.set({
          ...place.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        _analyticsRepo?.logEvent(
          eventType: 'PLACE_SAVED',
          placeId: place.id,
          destinationId: place.name,
        );
      }
    } catch (e) {
      debugPrint('[SavedPlacesRepository] toggle error: $e');
    }
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
