
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  ReportService._();

  static const List<String> reasons = [
    'Misleading animal information',
    'Suspected scam',
    'Inappropriate content',
    'Animal welfare concern',
    'Other',
  ];

  static Future<String> submitReport({
    required String postId,
    required String reason,
    required String description,
  }) async {
    // 1. Check authentication
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in to report a post.');
    }

    // 2. Validate selected reason
    if (!reasons.contains(reason)) {
      throw Exception('Please select a valid report reason.');
    }

    final cleanDescription = description.trim();

    if (reason == 'Other' && cleanDescription.isEmpty) {
      throw Exception('Please describe the issue.');
    }

    if (cleanDescription.length > 1000) {
      throw Exception('Description cannot exceed 1000 characters.');
    }

    if (postId.trim().isEmpty) {
      throw Exception('Invalid animal post.');
    }

    // 3. Fetch the reported animal post
    final postSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .get();

    final postData = postSnapshot.data();

    if (postData == null) {
      throw Exception('This animal post no longer exists.');
    }

    // 4. Identify the owner of the reported post
    final reportedUserId = postData['userId'];

    if (reportedUserId is! String ||
        reportedUserId.trim().isEmpty) {
      throw Exception('Post owner information is missing.');
    }

    // 5. Create report using the agreed admin schema
    final report = await FirebaseFirestore.instance
        .collection('post_reports')
        .add({
      'postId': postId,
      'reporterId': user.uid,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'description': cleanDescription,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
      'resolvedBy': null,
    });

    return report.id;
  }
}

