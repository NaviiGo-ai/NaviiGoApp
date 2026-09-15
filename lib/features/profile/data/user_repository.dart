import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/network/firebase_client.dart';
import '../domain/models/user_preferences_model.dart';
import '../domain/models/user_profile_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseClient.firestore;

  Stream<UserProfileModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfileModel.fromFirestore(doc) : null);
  }

  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfileModel.fromFirestore(doc);
  }

  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? photoURL,
  }) async {
    final data = <String, dynamic>{'lastLogin': FieldValue.serverTimestamp()};
    if (displayName != null) data['displayName'] = displayName.trim();
    if (photoURL != null) data['photoURL'] = photoURL.trim();

    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  /// Stream user preferences matching website users/{uid}/preferences/main
  Stream<UserPreferencesModel> getUserPreferencesStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('main')
        .snapshots()
        .map((doc) => UserPreferencesModel.fromFirestore(doc));
  }

  /// Get user preferences
  Future<UserPreferencesModel> getUserPreferences(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('main')
        .get();
    return UserPreferencesModel.fromFirestore(doc);
  }

  /// Update user preferences
  Future<void> updateUserPreferences(
    String uid,
    UserPreferencesModel prefs,
  ) async {
    final data = prefs.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('main')
        .set(data, SetOptions(merge: true));
  }
}
