import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  late String email;
  late String password;
  late String fullName;
  late String role;
  // late List<String> sensorIds; // Changed from code to sensorIds
  String imageUrl;

  Users({
    required this.email,
    required this.fullName,
    required this.password,
    required this.role,
    // required this.sensorIds, // Changed from code to sensorIds
    this.imageUrl = 'assets/images/default.jpg',
  });

  toJson() {
    return {
      'Uid': FirebaseAuth.instance.currentUser!.uid,
      'email': email,
      'password': password,
      'fullName': fullName,
      // 'sensorIds': sensorIds, // Changed from code to sensorIds
      'profilePic': imageUrl,
    };
  }

  factory Users.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Users(
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      password: data['password'] ?? '',
      role: data['role'] ?? 'user',
      // sensorIds: List<String>.from(data['sensorIds'] ?? []),
      imageUrl: data['profilePic'] ?? 'assets/images/default.jpg',
    );
  }
}
