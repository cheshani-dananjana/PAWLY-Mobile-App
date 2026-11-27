import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/admin_service.dart';

class ManageReportsScreen extends StatefulWidget {
  const ManageReportsScreen({super.key});

  @override
  State<ManageReportsScreen> createState() => _ManageReportsScreenState();
}

class _ManageReportsScreenState extends State<ManageReportsScreen> {
  final AdminService _service = AdminService();

  static const Color brown = Color(0xFF4A2915);
  static const Color cream = Color(0xFFFFF7EC);
  static const Color orange = Color(0xFFBF5700);
  static const Color darkRed = Color(0xFF8B0000);

  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  String _filter = 'all';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _stream = _service.getReports();
  }

  // =====================================
  // REPORT STATUS COLORS
  // =====================================

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'resolved':
        return Colors.green;

      case 'dismissed':
        return Colors.grey;

      default:
        return Colors.blueGrey;
    }
  }

  // =====================================
  // CONFIRM ADMIN ACTION
  // =====================================

  Future<void> _performAction(
    String message,
    Future<void> Function() action, {
    String successMessage = 'Action completed successfully.',
  }) async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: brown,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _busy) return;

    setState(() => _busy = true);

    try {
      await action();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // =====================================
  // VIEW REPORTED USER
  // =====================================

  Future<void> _viewReportedUser(String uid) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final user = await _service.getReportedUser(uid);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reported User'),
          content: user == null
              ? const Text('User profile not found.')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: brown,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Name: ${user['full_name'] ?? '-'}'),
                      const SizedBox(height: 8),
                      Text('Email: ${user['email'] ?? '-'}'),
                      const SizedBox(height: 8),
                      Text('Role: ${user['role'] ?? '-'}'),
                      const SizedBox(height: 8),
                      Text('Status: ${user['account_status'] ?? '-'}'),
                      const SizedBox(height: 8),
                      Text('UID: $uid'),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load user: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // =====================================
  // REQUEST USER DELETION
  // =====================================

  Future<void> _requestDeletion(String reportId, String reportedUserId) async {
    await _performAction(
      'Are you sure you want to submit a permanent '
      'account deletion request?\n\n'
      'The reported account will be disabled and '
      'the request will be sent for administrator review.\n\n'
      'This action does not permanently delete '
      'the account immediately.',
      () => _service.requestUserDeletion(reportId, reportedUserId),
      successMessage: 'Deletion request submitted. Account disabled.',
    );
  }

  // =====================================
  // REPORT CARD
  // =====================================

  Widget _reportCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    final reportId = document.id;
    final postId = '${data['postId'] ?? ''}';
    final reporterId = '${data['reporterId'] ?? ''}';
    final reportedUserId = '${data['reportedUserId'] ?? ''}';

    final reason = '${data['reason'] ?? 'Not specified'}';

    final description = '${data['description'] ?? ''}';

    final status = '${data['status'] ?? 'unknown'}';

    final createdAt = data['createdAt'];

    final date = createdAt is Timestamp
        ? createdAt.toDate().toLocal().toString().split('.').first
        : 'Unknown date';

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // REPORT HEADER

            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: brown,
                  child: Icon(Icons.flag, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Animal Post Report',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: brown,
                    ),
                  ),
                ),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _statusColor(status),
                  ),
                ),
              ],
            ),

            const Divider(),

            // REPORT DETAILS
            Text(
              'Reason: $reason',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              description.isEmpty ? 'No additional description.' : description,
            ),

            const SizedBox(height: 12),

            Text('Post ID: $postId'),

            const SizedBox(height: 5),

            Text('Reporter ID: $reporterId'),

            const SizedBox(height: 5),

            Text('Reported User ID: $reportedUserId'),

            const SizedBox(height: 5),

            Text('Reported Date: $date'),

            if (status == 'resolved' || status == 'dismissed') ...[
              const SizedBox(height: 5),
              Text('Reviewed by: ${data['resolvedBy'] ?? '-'}'),
            ],

            const SizedBox(height: 12),

            // VIEW REPORTED USER BUTTON
            OutlinedButton.icon(
              onPressed: _busy || reportedUserId.isEmpty
                  ? null
                  : () => _viewReportedUser(reportedUserId),
              icon: const Icon(Icons.person_search),
              label: const Text('View Reported User'),
              style: OutlinedButton.styleFrom(foregroundColor: brown),
            ),

            // PENDING REPORT ACTIONS
            if (status == 'pending') ...[
              const Divider(),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // RESOLVE REPORT

                  ElevatedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _performAction(
                            'Mark this report as resolved?',
                            () => _service.resolveReport(reportId),
                          ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // DISMISS REPORT
                  ElevatedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _performAction(
                            'Dismiss this report?',
                            () => _service.dismissReport(reportId),
                          ),
                    icon: const Icon(Icons.close),
                    label: const Text('Dismiss'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // BAN REPORTED USER
                  ElevatedButton.icon(
                    onPressed: _busy || reportedUserId.isEmpty
                        ? null
                        : () => _performAction(
                            'Ban this reported user? '
                            'The report will remain pending.',
                            () => _service.banUser(reportedUserId),
                          ),
                    icon: const Icon(Icons.block),
                    label: const Text('Ban User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // DISABLE REPORTED USER
                  ElevatedButton.icon(
                    onPressed: _busy || reportedUserId.isEmpty
                        ? null
                        : () => _performAction(
                            'Disable this reported user? '
                            'The report will remain pending.',
                            () => _service.disableUser(reportedUserId),
                          ),
                    icon: const Icon(Icons.person_off),
                    label: const Text('Disable User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],

            // =====================================
            // NEW REQUEST DELETION BUTTON
            // =====================================
            if (status == 'pending' || status == 'resolved') ...[
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy || reportedUserId.isEmpty
                      ? null
                      : () => _requestDeletion(reportId, reportedUserId),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Request Deletion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Permanent deletion requires authorized review.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =====================================
  // MAIN SCREEN
  // =====================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        title: const Text('Manage Reports'),
        backgroundColor: brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh Reports',
            icon: const Icon(Icons.refresh),
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _stream = _service.getReports();
                    });
                  },
          ),
        ],
      ),

      body: Column(
        children: [
          // REPORT STATUS FILTERS

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                for (final status in [
                  'all',
                  'pending',
                  'resolved',
                  'dismissed',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status.toUpperCase()),
                      selected: _filter == status,
                      selectedColor: const Color(0xFFF4DFC5),
                      onSelected: (_) {
                        setState(() {
                          _filter = status;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),

          // LOADING INDICATOR
          if (_busy) const LinearProgressIndicator(color: orange),

          // FIRESTORE REPORT STREAM
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                // ERROR HANDLING

                if (snapshot.hasError) {
                  debugPrint('REPORT ERROR: ${snapshot.error}');

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 55,
                            color: Colors.red,
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Unable to load reports.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Check Firestore permissions '
                            'and internet connection.',
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 12),

                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _stream = _service.getReports();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // WAIT FOR SERVER DATA

                if (!snapshot.hasData || snapshot.data!.metadata.isFromCache) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: brown),
                        SizedBox(height: 12),
                        Text('Connecting to Firestore...'),
                      ],
                    ),
                  );
                }

                // FILTER REPORTS

                final reports = snapshot.data!.docs.where((document) {
                  if (_filter == 'all') {
                    return true;
                  }

                  return document.data()['status'] == _filter;
                }).toList();

                // EMPTY STATE

                if (reports.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_outlined, size: 65, color: brown),

                        SizedBox(height: 12),

                        Text(
                          'No reports found.',
                          style: TextStyle(color: brown, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // DISPLAY REPORTS

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    return _reportCard(reports[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
