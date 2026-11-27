import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/admin_service.dart';

class DeletionRequestsScreen extends StatefulWidget {
  const DeletionRequestsScreen({super.key});

  @override
  State<DeletionRequestsScreen> createState() => _DeletionRequestsScreenState();
}

class _DeletionRequestsScreenState extends State<DeletionRequestsScreen> {
  final AdminService _service = AdminService();

  static const Color brown = Color(0xFF4A2915);
  static const Color cream = Color(0xFFFFF7EC);
  static const Color orange = Color(0xFFBF5700);

  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _stream = _service.getDeletionRequests();
  }

  // STATUS COLORS

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // DATE FORMAT

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toLocal().toString().split('.').first;
    }

    return 'Unknown date';
  }

  // VIEW REPORTED USER

  Future<void> _viewUser(String uid) async {
    try {
      final user = await _service.getReportedUser(uid);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reported User Details'),
          content: user == null
              ? const Text('User profile is no longer available.')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: brown,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
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
    }
  }

  // REQUEST CARD

  Widget _requestCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    final userId = '${data['userId'] ?? ''}';
    final reportId = '${data['reportId'] ?? '-'}';
    final requestedBy = '${data['requestedBy'] ?? '-'}';
    final reason = '${data['reason'] ?? '-'}';
    final status = '${data['status'] ?? 'unknown'}';

    final color = _statusColor(status);

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: brown,
                  child: Icon(Icons.delete_outline, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Account Deletion Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: brown,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            Text(
              'Reason: $reason',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text('User ID: $userId'),
            const SizedBox(height: 6),

            Text('Report ID: $reportId'),
            const SizedBox(height: 6),

            Text('Requested By: $requestedBy'),
            const SizedBox(height: 6),

            Text(
              'Requested Date: '
              '${_formatDate(data['createdAt'])}',
            ),

            if (data['reviewedBy'] != null) ...[
              const SizedBox(height: 6),
              Text('Reviewed By: ${data['reviewedBy']}'),
            ],

            if (data['reviewedAt'] != null) ...[
              const SizedBox(height: 6),
              Text(
                'Reviewed Date: '
                '${_formatDate(data['reviewedAt'])}',
              ),
            ],

            if (data['reviewNote'] != null) ...[
              const SizedBox(height: 6),
              Text('Review Note: ${data['reviewNote']}'),
            ],

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: userId.isEmpty ? null : () => _viewUser(userId),
                icon: const Icon(Icons.person_search),
                label: const Text('View Reported User'),
                style: OutlinedButton.styleFrom(foregroundColor: brown),
              ),
            ),

            if (status == 'pending') ...[
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Account disabled. Awaiting review '
                        'by an authorized Firebase administrator.',
                        style: TextStyle(color: brown, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // MAIN SCREEN

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        title: const Text('Deletion Requests'),
        backgroundColor: brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _stream = _service.getDeletionRequests();
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: brown,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Deletion Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'View and track reported account '
                  'deletion requests.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // FILTERS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final status in [
                  'all',
                  'pending',
                  'approved',
                  'completed',
                  'rejected',
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

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                    'DELETION REQUEST ERROR: '
                    '${snapshot.error}',
                  );

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        const Text('Unable to load deletion requests.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _stream = _service.getDeletionRequests();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.metadata.isFromCache) {
                  return const Center(
                    child: CircularProgressIndicator(color: brown),
                  );
                }

                final requests = snapshot.data!.docs.where((document) {
                  if (_filter == 'all') {
                    return true;
                  }

                  return document.data()['status'] == _filter;
                }).toList();

                if (requests.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 65, color: brown),
                        SizedBox(height: 12),
                        Text(
                          'No deletion requests found.',
                          style: TextStyle(color: brown, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _requestCard(requests[index]);
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
