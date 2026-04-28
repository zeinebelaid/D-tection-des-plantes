import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chaatbot_detection/models/user.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in user
  Future<String?> signInUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        return "Please verify your email before signing in.";
      }

      // Update emailVerified status in Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({'emailVerified': true});

      return "User signed in successfully!";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  // Sign out user
  Future<void> signOutUser() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user data from Firestore
  Future<Users?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return Users(
          email: doc['email'],
          fullName: doc['fullName'],
          password: doc['password'],
          role: doc['role'] ?? 'user',
          // sensorIds: List<String>.from(doc['sensorIds'] ?? []),
          imageUrl: doc['profilePic'] ?? 'assets/images/default.jpg',
        );
      }
    }
    return null;
  }

  // Extra signup method (not really needed if you already have registerUser)
  Future<String?> signUpUser(
      String email, String password, String fullName) async {
    try {
      // Create the user account
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Create user with the provided sensorId
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'fullName': fullName,
        'password': password,
        'role': 'user',
        // 'sensorIds': [sensorId],
        'profilePic': 'assets/images/default.jpg',
        'emailVerified': false,
      });

      return "User registered successfully! Please check your email for verification.";
    } catch (e) {
      print("Error during sign up: $e");
      return "Error: ${e.toString()}";
    }
  }

  // Add a method to check email verification status
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }
}
