import 'dart:math' as math;

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
  static const Color cream = Color(0xFFFCE8C9);
  static const Color orange = Color(0xFFBF5700);

  static const Color cardCream = Color(0xFFFFF6E9);
  static const Color peach = Color(0xFFF0C9AE);
  static const Color muted = Color(0xFF805237);

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
        return const Color(0xFFA45100);
      case 'approved':
        return const Color(0xFF355D91);
      case 'completed':
        return const Color(0xFF287044);
      case 'rejected':
        return const Color(0xFFAA3636);
      default:
        return const Color(0xFF75665C);
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
          backgroundColor: cardCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
                          backgroundColor: Color(0xFFF5D8B9),
                          child: Icon(Icons.person, size: 40, color: brown),
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
      color: cardCream,
      surfaceTintColor: Colors.transparent,
      shadowColor: brown.withValues(alpha: 0.15),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: peach),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFF5D8B9),
                  child: Icon(Icons.delete_outline, color: brown),
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

            const Divider(height: 25, color: peach),

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
                style: OutlinedButton.styleFrom(
                  foregroundColor: brown,
                  side: const BorderSide(color: peach),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
        backgroundColor: cream,
        foregroundColor: brown,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: brown,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
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

      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [cream, Color(0xFFFFE9CC), Color(0xFFF4C7A0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(top: 12, right: 18, child: _DeletionPaw(size: 46)),
            const Positioned(
              top: 260,
              left: -8,
              child: _DeletionPaw(size: 52, angle: -0.4, phase: 0.3),
            ),
            const Positioned(
              bottom: 18,
              right: 12,
              child: _DeletionPaw(size: 70, angle: 0.5, phase: 0.6),
            ),
            Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [cardCream, Color(0xFFF9D5AD)],
                    ),
                    border: Border.all(color: peach),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Deletion Management',
                        style: TextStyle(
                          color: brown,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'View and track reported account '
                        'deletion requests.',
                        style: TextStyle(color: muted, fontSize: 13),
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
                            selectedColor: const Color(0xFFF5C99C),
                            backgroundColor: cardCream,
                            side: const BorderSide(color: peach),
                            labelStyle: const TextStyle(
                              color: brown,
                              fontWeight: FontWeight.w600,
                            ),
                            checkmarkColor: brown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
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

                      if (!snapshot.hasData ||
                          snapshot.data!.metadata.isFromCache) {
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
                        return Center(
                          child: _entrance(
                            const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 42,
                                  backgroundColor: cardCream,
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 40,
                                    color: brown,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No deletion requests found.',
                                  style: TextStyle(
                                    color: brown,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Requests will appear here.',
                                  style: TextStyle(color: muted),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          return _entrance(
                            _requestCard(requests[index]),
                            key: ValueKey(requests[index].id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _entrance(Widget child, {Key? key}) {
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0.0, end: 1.0),
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _DeletionPaw extends StatefulWidget {
  const _DeletionPaw({required this.size, this.angle = 0.25, this.phase = 0.0});
  final double size, angle, phase;

  @override
  State<_DeletionPaw> createState() => _DeletionPawState();
}

class _DeletionPawState extends State<_DeletionPaw>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          child: Icon(
            Icons.pets,
            size: widget.size,
            color: const Color(0xFFC88A4D).withValues(alpha: 0.18),
          ),
          builder: (context, child) {
            final wave = MediaQuery.of(context).disableAnimations
                ? 0.0
                : math.sin(2 * math.pi * (_controller.value + widget.phase));
            return Transform.translate(
              offset: Offset(0, 6 * wave),
              child: Transform.rotate(
                angle: widget.angle + .07 * wave,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}
