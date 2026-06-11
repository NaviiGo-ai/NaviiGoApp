import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseClient {
  FirebaseClient._();

  static Future<void> init() async {
    // Note: Requires google-services.json / GoogleService-Info.plist in platform dirs
    // Wrapped in a try-catch for local development setup if files are missing.
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Log errors or print warning during mock runs
      // print("Firebase initialization deferred: $e");
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
