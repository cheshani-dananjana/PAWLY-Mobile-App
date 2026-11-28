import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {}
      }

      return 'Something went wrong: $e';
    }
  }

  // Login and Account Validation
  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get(const GetOptions(source: Source.server));

      final data = doc.data();

      if (data == null ||
          data['account_status'] != 'active' ||
          !['admin', 'user'].contains(data['role'])) {
        await _auth.signOut();

        return 'Account blocked or profile unavailable. '
            'Contact support.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      await _auth.signOut();
      return _getAuthErrorMessage(e);
    } catch (e) {
      await _auth.signOut();

      return 'Unable to verify account. Please try again.';
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

  // Get User Profile from Firestore
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

  // Change the signed-in user's password after fresh verification.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return 'Please log in again.';
    if (currentPassword.isEmpty) return 'Enter your current password.';
    if (newPassword.length < 8) return 'Use at least 8 characters.';
    if (currentPassword == newPassword) return 'Choose a different password.';
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
      if (_auth.currentUser?.uid != user.uid) return 'Please log in again.';
      final profile = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      final data = profile.data();
      if (data == null ||
          data['account_status'] != 'active' ||
          !['admin', 'user'].contains(data['role'])) {
        return 'Account blocked or profile unavailable.';
      }
      if (_auth.currentUser?.uid != user.uid) return 'Please log in again.';
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if ([
        'wrong-password',
        'invalid-credential',
        'invalid-login-credentials',
      ].contains(e.code)) {
        return 'Current password is incorrect.';
      }
      if (e.code == 'requires-recent-login') {
        return 'Please log in again and retry.';
      }
      return _getAuthErrorMessage(e);
    } catch (_) {
      return 'Unable to change password. Please try again.';
    }
  }

  // Logout
  Future<void> logOut() async {
    await _auth.signOut();
  }

  // Authentication Error Messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Password is too weak.';

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
        return 'Please check your internet connection.';

      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
