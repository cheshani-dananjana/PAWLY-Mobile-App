import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/services/auth_service.dart';
import '../adoption/my_applications_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:pawly/features/auth/screens/login_screen.dart';
import '../animals/my_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onOpenSaved});
  final VoidCallback onOpenSaved;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = '';
  String _phone = '';
  String _email = '';
  bool _loaded = false;
  bool _pushNotifications = true;
  bool _emailAlerts = true;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _profileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (doc) {
            if (!mounted) return;
            final data = doc.data();
            setState(() {
              _loaded = data != null;
              _displayName = data?['full_name']?.toString() ?? '';
              _phone = data?['phone_number']?.toString() ?? '';
              _email = data?['email']?.toString() ?? user.email ?? '';
            });
          },
          onError: (Object error) {
            if (mounted) setState(() => _loaded = false);
          },
        );
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  // 1. Edit Profile Modal
  void _openEditProfile() async {
    if (!_loaded) return;
    final nameController = TextEditingController(text: _displayName);
    final phoneController = TextEditingController(text: _phone);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFDF8ED),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF251605),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBF5700),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter your name.')),
                    );
                    return;
                  }
                  final error = await AuthService().updateUserProfile(
                    fullName: nameController.text,
                    phoneNumber: phoneController.text,
                  );
                  if (!context.mounted) return;
                  if (error != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(error)));
                    return;
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSavedAnimals() => widget.onOpenSaved();

  // 3. Notifications Modal
  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDF8ED),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification Preferences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF251605),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text(
                  'Push Notifications',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Receive alerts when new animals are posted nearby',
                ),
                value: _pushNotifications,
                activeThumbColor: const Color(0xFFBF5700),
                onChanged: (val) {
                  setModalState(() => _pushNotifications = val);
                  setState(() => _pushNotifications = val);
                },
              ),
              SwitchListTile(
                title: const Text(
                  'Email Alerts',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Receive weekly digest of adopted and stray pets',
                ),
                value: _emailAlerts,
                activeThumbColor: const Color(0xFFBF5700),
                onChanged: (val) {
                  setModalState(() => _emailAlerts = val);
                  setState(() => _emailAlerts = val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Privacy & Security Modal
  void _openPrivacySecurity() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDF8ED),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy & Security',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF251605),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Color(0xFFBF5700)),
              title: const Text(
                'Change Password',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset link sent to your email!'),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Delete Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _email;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8ED),
      body: Stack(
        children: [
          // More Dog & Cat Footmarks with slightly darker/clearer opacity for a colorful vibe
          Positioned(
            top: 50,
            right: 30,
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(
                Icons.pets,
                size: 36,
                color: const Color(0xFFBF5700).withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            top: 130,
            left: 20,
            child: Transform.rotate(
              angle: -0.3,
              child: Icon(
                Icons.pets,
                size: 28,
                color: const Color(0xFFBF5700).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: 50,
            child: Transform.rotate(
              angle: 0.2,
              child: Icon(
                Icons.pets,
                size: 42,
                color: const Color(0xFFBF5700).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            top: 340,
            left: 35,
            child: Transform.rotate(
              angle: -0.5,
              child: Icon(
                Icons.pets,
                size: 32,
                color: const Color(0xFFBF5700).withValues(alpha: 0.13),
              ),
            ),
          ),
          Positioned(
            top: 460,
            right: 25,
            child: Transform.rotate(
              angle: 0.4,
              child: Icon(
                Icons.pets,
                size: 38,
                color: const Color(0xFFBF5700).withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            bottom: 180,
            left: 40,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(
                Icons.pets,
                size: 45,
                color: const Color(0xFFBF5700).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 45,
            child: Transform.rotate(
              angle: 0.6,
              child: Icon(
                Icons.pets,
                size: 34,
                color: const Color(0xFFBF5700).withValues(alpha: 0.13),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated South Asian Natural Profile Picture
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFBF5700),
                        width: 2.5,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 52,
                      child: Icon(Icons.person, size: 52),
                    ),
                  ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const SizedBox(height: 16),
                  Text(
                    _loaded ? _displayName : 'Profile unavailable',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF251605),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8A7A66),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _phone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8A7A66),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Stylish Spaced Cards for Menu Items
                  _buildProfileCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Update your name and phone number',
                    onTap: _openEditProfile,
                  ),
                  _buildProfileCard(
                    icon: Icons.favorite_rounded,
                    title: 'Saved Animals',
                    subtitle: 'View your favorite rescued pets',
                    onTap: _openSavedAnimals,
                  ),

_buildProfileCard(
  icon: Icons.article_outlined,
  title: 'My Posts',
  subtitle: 'View, edit or delete your animal posts',
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MyPostsScreen(),
      ),
    );
  },
),


                  _buildProfileCard(
                    icon: Icons.assignment_outlined,
                    title: 'My Applications',
                    subtitle: 'Track your adoption and foster requests',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyApplicationsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildProfileCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage push alerts & email digests',
                    onTap: _openNotifications,
                  ),
                  _buildProfileCard(
                    icon: Icons.security_rounded,
                    title: 'Privacy & Security',
                    subtitle: 'Password, security & account options',
                    onTap: _openPrivacySecurity,
                  ),
                  const SizedBox(height: 28),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance.signOut();
                        } on FirebaseAuthException {
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not log out. Please try again.',
                              ),
                            ),
                          );
                          return;
                        }

                        if (!mounted) return;

                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBF5700).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFFBF5700), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF251605),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8A7A66),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF8A7A66),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
