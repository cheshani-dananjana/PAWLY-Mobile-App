import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:pawly/features/auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Editable profile state
  String _displayName = 'Thulakshie Attanayake';
  String _phone = '+94 77 123 4567';
  bool _pushNotifications = true;
  bool _emailAlerts = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      _displayName = user.displayName!;
    }
  }

  // 1. Edit Profile Modal
  void _openEditProfile() {
    final nameController = TextEditingController(text: _displayName);
    final phoneController = TextEditingController(text: _phone);

    showModalBottomSheet(
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
                onPressed: () {
                  setState(() {
                    _displayName = nameController.text;
                    _phone = phoneController.text;
                  });
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

  // 2. Saved Animals Modal
  void _openSavedAnimals() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDF8ED),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saved Paws',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF251605),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
                      ),
                    ),
                    title: Text(
                      'Max (Golden Retriever)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Horana · 2 years'),
                    trailing: Icon(Icons.favorite, color: Color(0xFFBF5700)),
                  ),
                  Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba',
                      ),
                    ),
                    title: Text(
                      'Luna (Tabby Cat)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Kurunegala · 1 year'),
                    trailing: Icon(Icons.favorite, color: Color(0xFFBF5700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                activeColor: const Color(0xFFBF5700),
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
                activeColor: const Color(0xFFBF5700),
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
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'thulakshie.att@gmail.com';

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
                color: const Color(0xFFBF5700).withOpacity(0.14),
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
                color: const Color(0xFFBF5700).withOpacity(0.12),
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
                color: const Color(0xFFBF5700).withOpacity(0.15),
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
                color: const Color(0xFFBF5700).withOpacity(0.13),
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
                color: const Color(0xFFBF5700).withOpacity(0.14),
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
                color: const Color(0xFFBF5700).withOpacity(0.15),
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
                color: const Color(0xFFBF5700).withOpacity(0.13),
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
                      backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80',
                      ),
                    ),
                  ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const SizedBox(height: 16),
                  Text(
                    _displayName,
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
            color: const Color(0xFFBF5700).withOpacity(0.08),
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
