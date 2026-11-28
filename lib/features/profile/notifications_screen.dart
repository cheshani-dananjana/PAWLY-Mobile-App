import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../adoption/adoption_service.dart';
import '../adoption/post_availability.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _background = Color(0xFFFBE8BC);
  static const _cream = Color(0xFFFDF8ED);
  static const _ink = Color(0xFF49270F);
  static const _accent = Color(0xFFBF5700);
  static const _muted = Color(0xFF80654F);

  Stream<QuerySnapshot>? _updates;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      _updates = AdoptionService().getUserApplications();
    }
  }

  Widget _message(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: _accent),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notification(Map<String, dynamic> data, String? availability) {
    final pet = (data['petName'] ?? 'Pet').toString();
    final status = (data['status'] ?? 'Pending').toString();
    final type = (data['applicationType'] ?? 'Adoption').toString();
    final IconData icon;
    final Color color;
    final String message;
    if (availability != null) {
      icon = Icons.info_outline;
      color = _muted;
      message = availability == 'Post Removed'
          ? 'This animal post is no longer available. Application status: $status.'
          : '$availability. Application status: $status.';
    } else {
      switch (status.toLowerCase()) {
        case 'approved':
          icon = Icons.check_circle_outline;
          color = Colors.green.shade700;
          message = 'Your application has been approved.';
          break;
        case 'rejected':
          icon = Icons.cancel_outlined;
          color = Colors.red.shade700;
          message = 'Your application was not approved.';
          break;
        case 'pending':
          icon = Icons.schedule;
          color = _accent;
          message = 'Your application is under review.';
          break;
        default:
          icon = Icons.info_outline;
          color = _muted;
          message = 'Current application status: $status.';
      }
    }
    return Card(
      color: _cream,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2B780)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$type - ${availability ?? status}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: _updates == null
            ? _message(
                Icons.lock_outline,
                'Sign in required',
                'Please sign in to see your application updates.',
              )
            : StreamBuilder<QuerySnapshot>(
                stream: _updates,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _message(
                      Icons.error_outline,
                      'Updates unavailable',
                      'Check your connection and reopen this screen.',
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _accent),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return _message(
                      Icons.notifications_none,
                      'No updates yet',
                      'Your adoption application updates will appear here.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Your latest application statuses',
                            style: TextStyle(color: _muted, fontSize: 14),
                          ),
                        );
                      }
                      final data =
                          docs[index - 1].data() as Map<String, dynamic>;
                      return PostAvailability(
                        key: ValueKey(docs[index - 1].id),
                        petId: data['petId'],
                        builder: (context, availability) =>
                            _notification(data, availability),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
