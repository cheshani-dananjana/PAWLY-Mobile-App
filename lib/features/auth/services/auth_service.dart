import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get Current Logged-in User
  User? get currentUser => _auth.currentUser;

  // Sign Up
  Future<String?> signUp(
    String fullName,
    String email,
    String password,
    String phoneNumber,
  ) async {
    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final newUser = UserModel(
        uid: credential.user!.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toMap());

      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {
          // Account cleanup failed
        }
      }

      return 'Something went wrong: $e';
    }
  }

  // Login
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  // Forgot Password
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return 'Unable to send reset email: $e';
    }
  }

  // Get User Profile
  Future<UserModel?> getUserProfile() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return null;
      }

      final document = await _firestore.collection('users').doc(user.uid).get();

      if (document.exists && document.data() != null) {
        return UserModel.fromMap(document.data()!, document.id);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Update User Profile
  Future<String?> updateUserProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return 'No user is currently logged in';
      }

      await _firestore.collection('users').doc(user.uid).update({
        'full_name': fullName.trim(),
        'phone_number': phoneNumber.trim(),
      });

      return null;
    } catch (e) {
      return 'Unable to update profile: $e';
    }
  }

  // Logout
  Future<void> logOut() async {
    await _auth.signOut();
  }

  // Firebase Authentication Error Messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
