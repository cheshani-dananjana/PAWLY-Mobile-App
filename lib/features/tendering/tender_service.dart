
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/cloudinary_upload_service.dart';

class TenderService {
  TenderService._();

  static const Set<String> allowedCareTypes = {
    'Food',
    'Water',
    'Medical Assistance',
    'Shelter',
  };

  static Future<String> submitCare({
    required String postId,
    required Set<String> careTypes,
    required String description,
    required File evidencePhoto,
  }) async {
    // Step 1: Verify the logged-in user.
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in to submit animal care.');
    }

    // Step 2: Validate the form.
    if (careTypes.isEmpty) {
      throw Exception('Select at least one type of care.');
    }

    if (!careTypes.every(allowedCareTypes.contains)) {
      throw Exception('Invalid care type selected.');
    }

    final cleanDescription = description.trim();

    if (cleanDescription.isEmpty) {
      throw Exception('Describe the care you provided.');
    }

    if (cleanDescription.length > 1000) {
      throw Exception('Description must be under 1000 characters.');
    }

    if (!await evidencePhoto.exists()) {
      throw Exception('Please select an evidence photograph.');
    }

    // Step 3: Verify the animal post exists.
    final postSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .get();

    final postData = postSnapshot.data();

    if (postData == null) {
      throw Exception('This animal post is no longer available.');
    }

    final animalName =
        (postData['animalName'] as String?) ?? 'Unnamed Pet';

    final reporterId =
        (postData['userId'] as String?) ?? '';

    // Step 4: Upload evidence to Cloudinary.
    final evidenceUrl =
        await CloudinaryUploadService.uploadAnimalImage(
      evidencePhoto,
    );

    // Step 5: Save the care record to Firestore.
    final selectedTypes = careTypes.toList()..sort();

    final record = await FirebaseFirestore.instance
        .collection('tender_records')
        .add({
      'postId': postId,
      'animalName': animalName,
      'reporterId': reporterId,
      'caregiverId': user.uid,
      'careTypes': selectedTypes,
      'description': cleanDescription,
      'evidenceImageUrl': evidenceUrl,
      'status': 'Submitted',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return record.id;
  }
}
