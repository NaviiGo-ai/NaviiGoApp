import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../cache/hive_service.dart';
import '../network/firebase_client.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseClient.auth,
      _firestore = firestore ?? FirebaseClient.firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user != null) {
      unawaited(syncUserProfile(credential.user!));
    }
    return credential;
  }

  /// Create a new account with email, password, and display name
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user != null) {
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName.trim());
      }
      unawaited(
        syncUserProfile(credential.user!, initialDisplayName: displayName),
      );
    }
    return credential;
  }

  /// Sync user profile with Firestore users/{uid} in naviigo-db
  /// Matches the exact contract in website lib/firestore.ts upsertUserProfile
  Future<void> syncUserProfile(User user, {String? initialDisplayName}) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final docSnap = await userDocRef.get();

      final now = FieldValue.serverTimestamp();
      final resolvedName = user.displayName ?? initialDisplayName;

      if (docSnap.exists) {
        await userDocRef.update({
          if (resolvedName != null) 'displayName': resolvedName,
          if (user.email != null) 'email': user.email,
          if (user.photoURL != null) 'photoURL': user.photoURL,
          'lastLogin': now,
        });
      } else {
        await userDocRef.set({
          'uid': user.uid,
          'displayName': resolvedName,
          'email': user.email,
          'photoURL': user.photoURL,
          'createdAt': now,
          'lastLogin': now,
          'totalTrips': 0,
          'totalBookings': 0,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[AuthRepository] syncUserProfile error: $e');
    }
  }

  /// Sign out and safely purge user-specific local caches
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await HiveService.clearCache();
    } catch (e) {
      debugPrint('[AuthRepository] Error clearing Hive cache on logout: $e');
    }
  }
}
