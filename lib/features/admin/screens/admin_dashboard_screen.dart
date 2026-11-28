import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/admin_service.dart';
import 'manage_users_screen.dart';
import 'manage_reports_screen.dart';
import 'blocked_users_screen.dart';
import 'deletion_requests_screen.dart';

import '../../auth/screens/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _service = AdminService();

  static const Color brown = Color(0xFF4A2915);
  static const Color cream = Color(0xFFFCE8C9);
  static const Color orange = Color(0xFFC65A00);
  static const Color lightBrown = Color(0xFF8B5E3C);

  late Future<Map<String, int>> _stats;
  late Future<int> _reportCount;
  late Future<int> _deletionCount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =====================================
  // LOAD DASHBOARD DATA
  // =====================================

  void _loadData() {
    _stats = _loadStats();
    _reportCount = _service.getPendingReportsCount();
    _deletionCount = _loadDeletionCount();
  }

  Future<Map<String, int>> _loadStats() async {
    await _service.checkAdminAccess();

    final db = FirebaseFirestore.instance;

    final users = await db.collection('users').count().get();

    final posts = await db.collection('posts').count().get();

    final blocked = await db
        .collection('users')
        .where('account_status', whereIn: ['banned', 'disabled'])
        .count()
        .get();

    return {
      'users': users.count ?? 0,
      'posts': posts.count ?? 0,
      'blocked': blocked.count ?? 0,
    };
  }

  Future<int> _loadDeletionCount() async {
    await _service.checkAdminAccess();

    final result = await FirebaseFirestore.instance
        .collection('deletion_requests')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    return result.count ?? 0;
  }

  // =====================================
  // REFRESH DASHBOARD
  // =====================================

  Future<void> _refreshDashboard() async {
    if (!mounted) return;

    setState(() {
      _loadData();
    });

    await Future.wait<void>([
      _stats.then<void>((_) {}, onError: (_) {}),
      _reportCount.then<void>((_) {}, onError: (_) {}),
      _deletionCount.then<void>((_) {}, onError: (_) {}),
    ]);
  }

  // =====================================
  // PAGE NAVIGATION
  // =====================================

  Future<void> _openPage(Widget page) async {
    try {
      await _service.checkAdminAccess();

      if (!mounted) return;

      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));

      if (!mounted) return;

      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access denied: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =====================================
  // ADMIN LOGOUT
  // =====================================

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static const Color dark = Color(0xFF251605);
  static const Color peach = Color(0xFFF0C9AE);
  static const Color muted = Color(0xFF805237);
  static const Color red = Color(0xFFAA3636);

  Widget _enter(Widget child, int order) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + order * 75),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        final t = MediaQuery.of(context).disableAnimations ? 1.0 : value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  String _countValue(AsyncSnapshot<int> snapshot) {
    if (snapshot.hasError) return 'N/A';
    if (!snapshot.hasData) return '...';
    return '${snapshot.data}';
  }

  Widget _counter(String value, {Color color = brown, double size = 30}) {
    final number = int.tryParse(value);
    final style = TextStyle(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1.15,
    );
    if (number == null || MediaQuery.of(context).disableAnimations) {
      return Text(value, style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: number.toDouble()),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (_, n, _) => Text('${n.round()}', style: style),
    );
  }

  BoxDecoration _surface() => BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFFFF6E9), Color(0xFFFFEBD6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: peach.withValues(alpha: .9)),
    boxShadow: [
      BoxShadow(
        color: brown.withValues(alpha: .08),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );

  Widget _iconTile(IconData icon, Color color) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Icon(icon, color: color, size: 25),
  );

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconTile(icon, color),
          const SizedBox(height: 10),
          _counter(value),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: _surface(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: orange.withValues(alpha: .15),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _iconTile(icon, color),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: dark,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: orange),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: dark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  );

  Widget _welcome() => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFEED7), Color(0xFFFFDBB1), Color(0xFFF5BB81)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: brown.withValues(alpha: .09),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          const Positioned(
            right: -8,
            top: -14,
            child: _FloatingPaw(size: 86, angle: -.35, opacity: .16, phase: 0),
          ),
          const Positioned(
            right: 74,
            bottom: 5,
            child: _FloatingPaw(size: 23, angle: .25, opacity: .18, phase: .5),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAWLY  /  ADMIN',
                        style: TextStyle(
                          color: Color(0xFF94501F),
                          letterSpacing: 1.5,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Welcome, Admin!',
                        style: TextStyle(
                          color: brown,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Keep our PAWLY community safe, one paw at a time.',
                        style: TextStyle(
                          color: Color(0xFF805237),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1DF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: peach),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFF805237),
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: cream,
        foregroundColor: brown,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.pets, size: 21),
            SizedBox(width: 9),
            Flexible(
              child: Text(
                'Admin Dashboard',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Dashboard',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCE8C9), Color(0xFFFFE9CC), Color(0xFFF4C7A0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 18,
              left: -8,
              child: _FloatingPaw(size: 57, angle: -.4, opacity: .19, phase: 0),
            ),
            const Positioned(
              top: 184,
              right: 3,
              child: _FloatingPaw(size: 34, angle: .4, opacity: .19, phase: .3),
            ),
            const Positioned(
              bottom: 50,
              right: -10,
              child: _FloatingPaw(
                size: 90,
                angle: .35,
                opacity: .16,
                phase: .6,
              ),
            ),
            const Positioned(
              bottom: 175,
              left: -5,
              child: _FloatingPaw(
                size: 45,
                angle: -.25,
                opacity: .20,
                phase: .8,
              ),
            ),
            RefreshIndicator(
              color: orange,
              backgroundColor: cream,
              onRefresh: _refreshDashboard,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final columns = textScale > 1.4 ? 1 : (wide ? 4 : 2);
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _enter(_welcome(), 0),
                            const SizedBox(height: 25),
                            _heading(
                              'Platform Overview',
                              'A quick look at your community',
                            ),
                            const SizedBox(height: 14),
                            FutureBuilder<Map<String, int>>(
                              future: _stats,
                              builder: (context, snapshot) {
                                String value(String key) {
                                  if (snapshot.hasError) return 'N/A';
                                  if (!snapshot.hasData) return '...';
                                  return '${snapshot.data![key] ?? 0}';
                                }

                                return GridView.count(
                                  crossAxisCount: columns,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent:
                                      160 +
                                      (textScale > 1
                                          ? (textScale - 1) * 80
                                          : 0),
                                  children: [
                                    _enter(
                                      _statCard(
                                        title: 'Total Users',
                                        value: value('users'),
                                        icon: Icons.people_rounded,
                                        color: const Color(0xFF79563D),
                                      ),
                                      1,
                                    ),
                                    _enter(
                                      _statCard(
                                        title: 'Animal Posts',
                                        value: value('posts'),
                                        icon: Icons.pets,
                                        color: lightBrown,
                                      ),
                                      2,
                                    ),
                                    FutureBuilder<int>(
                                      future: _reportCount,
                                      builder: (_, report) => _enter(
                                        _statCard(
                                          title: 'Pending Reports',
                                          value: _countValue(report),
                                          icon: Icons.flag_rounded,
                                          color: orange,
                                        ),
                                        3,
                                      ),
                                    ),
                                    _enter(
                                      _statCard(
                                        title: 'Blocked Users',
                                        value: value('blocked'),
                                        icon: Icons.block_rounded,
                                        color: red,
                                      ),
                                      4,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<int>(
                              future: _deletionCount,
                              builder: (_, snapshot) => _enter(
                                Container(
                                  decoration: _surface(),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      _iconTile(
                                        Icons.delete_outline_rounded,
                                        red,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pending Deletion Requests',
                                              style: TextStyle(
                                                color: dark,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Awaiting authorized review',
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _counter(
                                        _countValue(snapshot),
                                        color: red,
                                        size: 25,
                                      ),
                                    ],
                                  ),
                                ),
                                5,
                              ),
                            ),
                            const SizedBox(height: 25),
                            _heading(
                              'Management Tools',
                              'Manage and protect the PAWLY community',
                            ),
                            const SizedBox(height: 14),
                            _enter(
                              _menuCard(
                                title: 'Manage Users',
                                subtitle: 'View and manage registered users',
                                icon: Icons.manage_accounts_rounded,
                                color: lightBrown,
                                onTap: () =>
                                    _openPage(const ManageUsersScreen()),
                              ),
                              6,
                            ),
                            _enter(
                              _menuCard(
                                title: 'Manage Reports',
                                subtitle: 'Review and resolve reported posts',
                                icon: Icons.flag_rounded,
                                color: orange,
                                onTap: () =>
                                    _openPage(const ManageReportsScreen()),
                              ),
                              7,
                            ),
                            _enter(
                              _menuCard(
                                title: 'Blocked Accounts',
                                subtitle: 'Manage banned and disabled accounts',
                                icon: Icons.block_rounded,
                                color: red,
                                onTap: () =>
                                    _openPage(const BlockedUsersScreen()),
                              ),
                              8,
                            ),
                            _enter(
                              _menuCard(
                                title: 'Deletion Requests',
                                subtitle:
                                    'View and track account deletion requests',
                                icon: Icons.delete_outline_rounded,
                                color: red,
                                onTap: () =>
                                    _openPage(const DeletionRequestsScreen()),
                              ),
                              9,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: _surface(),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    color: brown,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Authorized administrator access only. Account actions are protected by Firebase Security Rules.',
                                      style: TextStyle(
                                        color: brown,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Center(
                              child: Text(
                                'PAWLY  •  Every paw deserves love',
                                style: TextStyle(color: muted, fontSize: 11),
                              ),
                            ),
                            const SizedBox(height: 12),
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
      ),
    );
  }
}

class _FloatingPaw extends StatefulWidget {
  const _FloatingPaw({
    required this.size,
    required this.angle,
    required this.opacity,
    required this.phase,
  });
  final double size, angle, opacity, phase;

  @override
  State<_FloatingPaw> createState() => _FloatingPawState();
}

class _FloatingPawState extends State<_FloatingPaw>
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
            color: const Color(0xFFC88A4D).withValues(alpha: widget.opacity),
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
