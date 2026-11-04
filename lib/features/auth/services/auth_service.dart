import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Sign Up
  Future<String?> signUp(String fullName, String email, String password) async {
    try {
      // Create user in Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user model
      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        fullName: fullName,
        email: email,
        createdAt: DateTime.now(),
      );

      // Save user to Firestore 'users' collection
      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(newUser.toMap());

      return null; // Success (no error message)
    } on FirebaseAuthException catch (e) {
      return e.message; // Return Firebase error message
    } catch (e) {
      return e.toString();
    }
  }

  // 2. Log In
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 3. Log Out
  Future<void> logOut() async {
    await _auth.signOut();
  }
}
