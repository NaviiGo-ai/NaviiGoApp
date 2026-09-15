import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final int totalTrips;
  final int totalBookings;

  const UserProfileModel({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.createdAt,
    this.lastLogin,
    this.totalTrips = 0,
    this.totalBookings = 0,
  });

  factory UserProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return UserProfileModel(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoURL: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      totalTrips: (data['totalTrips'] as num?)?.toInt() ?? 0,
      totalBookings: (data['totalBookings'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'totalTrips': totalTrips,
      'totalBookings': totalBookings,
    };
  }

  String get initials {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length > 1) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email!.substring(0, 2).toUpperCase();
    }
    return 'NV';
  }
}
