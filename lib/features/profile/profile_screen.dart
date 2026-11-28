import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/services/auth_service.dart';
import '../adoption/my_applications_screen.dart';
import '../animals/my_posts_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:pawly/features/auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onOpenSaved});
  final VoidCallback onOpenSaved;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _avatar = 0;
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
                    content: Text(
                      'Password reset is not available from this screen yet.',
                    ),
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

  static const _ink = Color(0xFF49270F);
  static const _accent = Color(0xFFBF5700);
  static const _cream = Color(0xFFFDF8ED);
  static const _peach = Color(0xFFF8E2BC);
  static const _muted = Color(0xFF80654F);
  static const _background = Color(0xFFFBE8BC);
  static const _avatars = ['Dog', 'Girl', 'Boy', 'Cat'];
  static const _avatarNames = _avatars;

  Future<void> _chooseAvatar() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose your avatar',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose any character you like.',
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(
                  _avatars.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.pop(context, index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _peach,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _avatar == index
                                  ? _accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: _character(
                                  index,
                                  MediaQuery.disableAnimationsOf(context),
                                ),
                              ),
                              Text(
                                _avatarNames[index],
                                style: const TextStyle(color: _ink),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted && picked != null) setState(() => _avatar = picked);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openApplications() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MyApplicationsScreen()));
  }

  void _openMyPosts() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MyPostsScreen()));
  }

  Widget _paw(double size, double angle, bool reduce) {
    final paw = Transform.rotate(
      angle: angle,
      child: Icon(
        Icons.pets,
        size: size,
        color: _accent.withValues(alpha: .12),
      ),
    );
    if (reduce) return paw;
    return paw
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: 0,
          end: -7,
          duration: Duration(milliseconds: 2100 + (size * 19).round()),
          curve: Curves.easeInOut,
        );
  }

  Widget _character(int index, bool reduce) {
    Widget face = CustomPaint(painter: _ProfileCharacterPainter(index));
    if (!reduce) {
      face = face
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 2, end: -3, duration: 1500.ms, curve: Curves.easeInOut)
          .rotate(
            begin: -.018,
            end: .018,
            duration: 1500.ms,
            curve: Curves.easeInOut,
          );
    }
    return face;
  }

  Widget _profileHeader(bool reduce, double height) {
    final avatar = _character(_avatar, reduce);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3DC), Color(0xFFF5D2A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withValues(alpha: .65), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            label: 'Choose profile avatar',
            child: Material(
              color: _cream,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _chooseAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _accent, width: 1.5),
                      ),
                      child: SizedBox(width: 76, height: 76, child: avatar),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _loaded ? _displayName : 'Profile unavailable',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
          if (_phone.isNotEmpty)
            Text(
              _phone,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          const SizedBox(height: 8),
          const Text(
            'PAWLY MEMBER',
            style: TextStyle(
              color: _ink,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? tap,
    bool reduce,
    double height,
  ) {
    Widget tile = Material(
      color: const Color(0xFFFFFCF6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: const BorderSide(color: Color(0xFFD78335)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tap,
        child: Container(
          constraints: BoxConstraints(minHeight: height),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8E5C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: _accent, size: 20),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    color: _muted,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
    if (!reduce) {
      tile = tile
          .animate()
          .fadeIn(duration: 350.ms)
          .moveY(begin: 6, end: 0, duration: 350.ms);
    }
    return tile;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _background),
          Positioned(
            top: 8,
            right: 14,
            child: IgnorePointer(child: _paw(36, .3, reduce)),
          ),
          Positioned(
            top: 100,
            left: 2,
            child: IgnorePointer(child: _paw(28, -.4, reduce)),
          ),
          Positioned(
            top: 225,
            right: 3,
            child: IgnorePointer(child: _paw(32, .45, reduce)),
          ),
          Positioned(
            top: 340,
            left: 2,
            child: IgnorePointer(child: _paw(26, -.4, reduce)),
          ),
          Positioned(
            bottom: 135,
            right: 2,
            child: IgnorePointer(child: _paw(34, .3, reduce)),
          ),
          Positioned(
            bottom: 18,
            left: 8,
            child: IgnorePointer(child: _paw(46, -.35, reduce)),
          ),
          Positioned(
            bottom: 18,
            right: 10,
            child: IgnorePointer(child: _paw(40, .45, reduce)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final heroHeight = (h * .28).clamp(178.0, 220.0).toDouble();
                final tileHeight = (h * .13).clamp(84.0, 112.0).toDouble();
                final narrow =
                    constraints.maxWidth < 320 ||
                    MediaQuery.textScalerOf(context).scale(14) > 19;
                final tiles = [
                  _tile(
                    Icons.person_outline_rounded,
                    'Edit Profile',
                    'Personal details',
                    _loaded ? _openEditProfile : null,
                    reduce,
                    tileHeight,
                  ),
                  _tile(
                    Icons.favorite_rounded,
                    'Saved Animals',
                    'Your favourites',
                    _openSavedAnimals,
                    reduce,
                    tileHeight,
                  ),
                  _tile(
                    Icons.assignment_outlined,
                    'My Applications',
                    'Track requests',
                    _openApplications,
                    reduce,
                    tileHeight,
                  ),
                  _tile(
                    Icons.article_outlined,
                    'My Posts',
                    'View, edit or delete',
                    _openMyPosts,
                    reduce,
                    tileHeight,
                  ),
                  _tile(
                    Icons.notifications_active_outlined,
                    'Notifications',
                    'Manage alerts',
                    _openNotifications,
                    reduce,
                    tileHeight,
                  ),
                  _tile(
                    Icons.security_rounded,
                    'Privacy & Security',
                    'Account settings',
                    _openPrivacySecurity,
                    reduce,
                    tileHeight,
                  ),
                ];
                Widget menuRow(int index) => narrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          tiles[index],
                          const SizedBox(height: 10),
                          tiles[index + 1],
                        ],
                      )
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: tiles[index]),
                            const SizedBox(width: 12),
                            Expanded(child: tiles[index + 1]),
                          ],
                        ),
                      );
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: (constraints.maxWidth - 32)
                            .clamp(0.0, 560.0)
                            .toDouble(),
                        maxWidth: 560,
                        minHeight: (h - 26)
                            .clamp(0.0, double.infinity)
                            .toDouble(),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'My Profile',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Your little corner of PAWLY',
                                style: TextStyle(color: _muted, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              _profileHeader(reduce, heroHeight),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Your account',
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                menuRow(0),
                                const SizedBox(height: 12),
                                menuRow(2),
                                const SizedBox(height: 10),
                                menuRow(4),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE98220),
                                      Color(0xFF713509),
                                      Color(0xFF49270F),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accent.withValues(alpha: .20),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text(
                                    'Log Out',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    minimumSize: const Size(0, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Local vector avatars: no assets, uploads or network calls.
class _ProfileCharacterPainter extends CustomPainter {
  const _ProfileCharacterPainter(this.index);
  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final p = Paint()..isAntiAlias = true;
    void oval(double x, double y, double w, double h, Color color) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        p
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    void path(List<Offset> points, Color color) {
      final shape = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        shape.lineTo(point.dx, point.dy);
      }
      shape.close();
      canvas.drawPath(
        shape,
        p
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    const ink = Color(0xFF49270F);
    const cream = Color(0xFFFFF4E4);
    const blush = Color(0xFFEBA18C);
    const orange = Color(0xFFD87725);
    final human = index == 1 || index == 2;
    if (human) {
      final girl = index == 1;
      const hair = Color(0xFF583525);
      const skin = Color(0xFFE5AE84);
      oval(50, 47, 68, girl ? 82 : 65, hair);
      oval(50, 89, 69, 34, girl ? orange : const Color(0xFF9F6C48));
      oval(50, 73, 19, 24, skin);
      oval(20, 48, 12, 18, skin);
      oval(80, 48, 12, 18, skin);
      oval(50, 46, 57, 64, skin);
      if (girl) {
        oval(34, 22, 33, 23, hair);
        oval(62, 20, 39, 23, hair);
        oval(20, 48, 11, 52, hair);
        oval(80, 48, 11, 52, hair);
        oval(75, 28, 9, 9, orange);
      } else {
        oval(50, 19, 62, 25, hair);
        oval(34, 27, 29, 17, hair);
      }
    } else {
      final cat = index == 3;
      const fur = Color(0xFFE0AD78);
      const ear = Color(0xFF98613A);
      if (cat) {
        path(const [Offset(19, 42), Offset(17, 8), Offset(43, 28)], ear);
        path(const [Offset(81, 42), Offset(83, 8), Offset(57, 28)], ear);
        path(const [Offset(23, 32), Offset(22, 17), Offset(35, 29)], blush);
        path(const [Offset(77, 32), Offset(78, 17), Offset(65, 29)], blush);
      } else {
        oval(19, 47, 23, 55, ear);
        oval(81, 47, 23, 55, ear);
      }
      oval(50, 87, 47, 23, orange);
      oval(50, 49, 66, 66, fur);
      if (!cat) {
        oval(50, 35, 17, 35, cream);
      }
      oval(50, 63, 44, 31, cream);
      oval(50, 58, 13, 9, ink);
      if (cat) {
        p
          ..color = ear
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        for (final y in [56.0, 62.0]) {
          canvas.drawLine(Offset(29, y), Offset(12, y - 3), p);
          canvas.drawLine(Offset(71, y), Offset(88, y - 3), p);
        }
      }
    }
    oval(37, 45, 7, 10, ink);
    oval(63, 45, 7, 10, ink);
    oval(38, 43, 2.5, 3, Colors.white);
    oval(64, 43, 2.5, 3, Colors.white);
    oval(29, 55, 10, 5, blush);
    oval(71, 55, 10, 5, blush);
    final smile = Path()
      ..moveTo(43, 65)
      ..quadraticBezierTo(50, 73, 57, 65);
    canvas.drawPath(
      smile,
      p
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    if (index == 0) {
      oval(50, 72, 9, 10, blush);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProfileCharacterPainter oldDelegate) =>
      oldDelegate.index != index;
}
