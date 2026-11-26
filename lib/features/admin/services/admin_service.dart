import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // CHECK ADMIN ACCESS
  Future<void> checkAdminAccess() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please login first.');
    }

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));

    final data = snapshot.data();

    if (data == null ||
        data['role'] != 'admin' ||
        data['account_status'] != 'active') {
      throw Exception('Administrator access denied.');
    }
  }

  // DASHBOARD STATISTICS
  Future<int> getTotalUsers() async {
    await checkAdminAccess();
    final result = await _db.collection('users').count().get();
    return result.count ?? 0;
  }

  Future<int> getTotalPosts() async {
    await checkAdminAccess();
    final result = await _db.collection('posts').count().get();
    return result.count ?? 0;
  }

  Future<int> getBlockedUsersCount() async {
    await checkAdminAccess();

    final result = await _db
        .collection('users')
        .where('account_status', whereIn: ['banned', 'disabled'])
        .count()
        .get();

    return result.count ?? 0;
  }

  // ACTUAL PENDING REPORTS COUNT
  Future<int> getPendingReportsCount() async {
    await checkAdminAccess();

    final result = await _db
        .collection('post_reports')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    return result.count ?? 0;
  }

  // GET ALL USERS
  Stream<QuerySnapshot<Map<String, dynamic>>> getUsers() async* {
    await checkAdminAccess();

    yield* _db.collection('users').snapshots(includeMetadataChanges: true);
  }

  // GET BLOCKED USERS
  Stream<QuerySnapshot<Map<String, dynamic>>> getBlockedUsers() async* {
    await checkAdminAccess();

    yield* _db
        .collection('users')
        .where('account_status', whereIn: ['banned', 'disabled'])
        .snapshots(includeMetadataChanges: true);
  }

  // UPDATE ACCOUNT STATUS
  Future<void> updateAccountStatus(String uid, String status) async {
    await checkAdminAccess();

    if (!['active', 'banned', 'disabled'].contains(status)) {
      throw Exception('Invalid account status.');
    }

    if (uid == _auth.currentUser?.uid) {
      throw Exception('You cannot modify your own account.');
    }

    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data();

      if (data == null) {
        throw Exception('User not found.');
      }

      if (data['role'] != 'user') {
        throw Exception('Only normal users can be modified.');
      }

      transaction.update(userRef, {'account_status': status});
    });
  }

  Future<void> banUser(String uid) async {
    await updateAccountStatus(uid, 'banned');
  }

  Future<void> disableUser(String uid) async {
    await updateAccountStatus(uid, 'disabled');
  }

  Future<void> reactivateUser(String uid) async {
    await updateAccountStatus(uid, 'active');
  }

  // GET ALL REPORTS
  Stream<QuerySnapshot<Map<String, dynamic>>> getReports() async* {
    await checkAdminAccess();

    yield* _db
        .collection('post_reports')
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  // GET REPORTED USER DETAILS
  Future<Map<String, dynamic>?> getReportedUser(String uid) async {
    await checkAdminAccess();

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));

    return snapshot.data();
  }

  // UPDATE REPORT STATUS
  Future<void> updateReportStatus(String reportId, String status) async {
    await checkAdminAccess();

    if (!['resolved', 'dismissed'].contains(status)) {
      throw Exception('Invalid report status.');
    }

    final adminId = _auth.currentUser!.uid;

    final reportRef = _db.collection('post_reports').doc(reportId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reportRef);
      final data = snapshot.data();

      if (data == null) {
        throw Exception('Report not found.');
      }

      if (data['status'] != 'pending') {
        throw Exception('Report already reviewed.');
      }

      transaction.update(reportRef, {
        'status': status,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': adminId,
      });
    });
  }

  Future<void> resolveReport(String reportId) async {
    await updateReportStatus(reportId, 'resolved');
  }

  Future<void> dismissReport(String reportId) async {
    await updateReportStatus(reportId, 'dismissed');
  }

  Future<void> requestUserDeletion(String reportId, String uid) async {
    await checkAdminAccess();

    final adminId = _auth.currentUser!.uid;

    if (uid == adminId) {
      throw Exception('You cannot delete your own account.');
    }

    final userRef = _db.collection('users').doc(uid);

    final reportRef = _db.collection('post_reports').doc(reportId);

    final requestRef = _db.collection('deletion_requests').doc(uid);

    await _db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final reportSnapshot = await transaction.get(reportRef);
      final requestSnapshot = await transaction.get(requestRef);

      final user = userSnapshot.data();
      final report = reportSnapshot.data();

      if (user == null) {
        throw Exception('User not found.');
      }

      if (user['role'] != 'user') {
        throw Exception('Admin accounts cannot be deleted.');
      }

      if (report == null ||
          report['reportedUserId'] != uid ||
          !['pending', 'resolved'].contains(report['status'])) {
        throw Exception('Valid report required.');
      }

      if (requestSnapshot.exists) {
        throw Exception('A deletion request already exists.');
      }

      transaction.set(requestRef, {
        'userId': uid,
        'reportId': reportId,
        'requestedBy': adminId,
        'reason': 'Reported account requires deletion review.',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(userRef, {'account_status': 'disabled'});
    });
  }
}
