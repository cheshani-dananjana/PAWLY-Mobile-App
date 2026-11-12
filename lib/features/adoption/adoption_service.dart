import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdoptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitApplication({
    required String petId,
    required String petName,
    required String applicationType,
    required String applicantName,
    required String applicantPhone,
    required String housingType,
    required bool hasOtherPets,
    required String experienceDetails,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User must be logged in to apply';

    await _firestore.collection('adoption_applications').add({
      'petId': petId,
      'petName': petName,
      'applicantId': user.uid,
      'applicantEmail': user.email ?? '',
      'applicantName': applicantName,
      'applicantPhone': applicantPhone,
      'applicationType': applicationType,
      'housingType': housingType,
      'hasOtherPets': hasOtherPets,
      'experienceDetails': experienceDetails,
      'status': 'Pending',
      'appliedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getUserApplications() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('adoption_applications')
        .where('applicantId', isEqualTo: user.uid)
        .orderBy('appliedAt', descending: true)
        .snapshots();
  }
}
