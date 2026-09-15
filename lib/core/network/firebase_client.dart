import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseClient {
  FirebaseClient._();

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Log errors or warning during mock runs
      debugPrint("Firebase initialization deferred: $e");
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'naviigo-db',
  );
}
