import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../home/home_feed_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAsRead(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(id)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: PawlyColors.cream,
      appBar: AppBar(
        backgroundColor: PawlyColors.amber,
        elevation: 0,
        title: Text(
          'Notifications',
          style: PawlyText.serif(size: 22),
        ),
        iconTheme: const IconThemeData(
          color: PawlyColors.espresso,
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view notifications.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load notifications.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final notifications = snapshot.data?.docs ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 65,
                          color: PawlyColors.muted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          style: PawlyText.serif(size: 19),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'We will let you know when something happens.',
                          style: PawlyText.sans(
                            color: PawlyColors.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final isRead = data['isRead'] == true;

                    return Card(
                      color: isRead
                          ? PawlyColors.surface
                          : PawlyColors.creamDeep,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: PawlyColors.amber,
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            color: PawlyColors.espresso,
                          ),
                        ),
                        title: Text(
                          data['title'] ?? 'Pawly Notification',
                          style: PawlyText.sans(
                            weight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          data['message'] ?? '',
                        ),
                        trailing: isRead
                            ? const Icon(
                                Icons.check_circle_outline,
                                color: PawlyColors.muted,
                              )
                            : const Icon(
                                Icons.circle,
                                size: 10,
                                color: PawlyColors.burntOrange,
                              ),
                        onTap: () async {
                          if (!isRead) {
                            await _markAsRead(doc.id);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}