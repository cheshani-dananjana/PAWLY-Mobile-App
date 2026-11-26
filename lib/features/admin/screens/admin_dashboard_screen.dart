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
  static const Color cream = Color(0xFFFFF7EC);
  static const Color orange = Color(0xFFBF5700);
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

  // =====================================
  // STATISTICS CARD
  // =====================================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: brown.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: brown,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================
  // ADMIN MENU CARD
  // =====================================

  Widget _menuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),

        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 26),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: brown,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),

        trailing: const Icon(Icons.chevron_right, color: brown),

        onTap: onTap,
      ),
    );
  }

  // =====================================
  // FORMAT STATISTICS
  // =====================================

  String _countValue(AsyncSnapshot<int> snapshot) {
    if (snapshot.hasError) return 'N/A';

    if (!snapshot.hasData) return '...';

    return '${snapshot.data}';
  }

  // =====================================
  // DASHBOARD UI
  // =====================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: brown,
        foregroundColor: Colors.white,

        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh Dashboard',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh),
          ),

          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: brown,
        onRefresh: _refreshDashboard,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================
              // WELCOME SECTION
              // ==========================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [brown, lightBrown],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Admin!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 8),

                          Text(
                            'Manage users, reports and '
                            'keep the PAWLY community safe.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Platform Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: brown,
                ),
              ),

              const SizedBox(height: 14),

              // ==========================
              // STATISTICS GRID
              // ==========================
              FutureBuilder<Map<String, int>>(
                future: _stats,
                builder: (context, snapshot) {
                  final data = snapshot.data;

                  String value(String key) {
                    if (snapshot.hasError) return 'N/A';

                    if (data == null) return '...';

                    return '${data[key] ?? 0}';
                  }

                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.10,

                    children: [
                      _statCard(
                        title: 'Total Users',
                        value: value('users'),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),

                      _statCard(
                        title: 'Animal Posts',
                        value: value('posts'),
                        icon: Icons.pets,
                        color: lightBrown,
                      ),

                      FutureBuilder<int>(
                        future: _reportCount,
                        builder: (context, snapshot) {
                          return _statCard(
                            title: 'Pending Reports',
                            value: _countValue(snapshot),
                            icon: Icons.flag,
                            color: orange,
                          );
                        },
                      ),

                      _statCard(
                        title: 'Blocked Users',
                        value: value('blocked'),
                        icon: Icons.block,
                        color: Colors.red,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // ==========================
              // PENDING DELETION COUNT
              // ==========================
              FutureBuilder<int>(
                future: _deletionCount,
                builder: (context, snapshot) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5E5),
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFF8B0000),
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Deletion Requests',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: brown,
                                  fontSize: 15,
                                ),
                              ),

                              SizedBox(height: 5),

                              Text(
                                'Awaiting authorized review',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          _countValue(snapshot),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B0000),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              // ==========================
              // ADMIN MANAGEMENT MENU
              // ==========================
              const Text(
                'Management Tools',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: brown,
                ),
              ),

              const SizedBox(height: 14),

              // MANAGE USERS
              _menuCard(
                title: 'Manage Users',
                subtitle: 'View and manage registered users',
                icon: Icons.manage_accounts,
                color: Colors.blue,

                onTap: () => _openPage(const ManageUsersScreen()),
              ),

              // MANAGE REPORTS
              _menuCard(
                title: 'Manage Reports',
                subtitle: 'Review and resolve reported posts',
                icon: Icons.flag,
                color: orange,

                onTap: () => _openPage(const ManageReportsScreen()),
              ),

              // BLOCKED ACCOUNTS
              _menuCard(
                title: 'Blocked Accounts',
                subtitle: 'Manage banned and disabled accounts',
                icon: Icons.block,
                color: Colors.red,

                onTap: () => _openPage(const BlockedUsersScreen()),
              ),

              // NEW DELETION REQUESTS SCREEN
              _menuCard(
                title: 'Deletion Requests',
                subtitle: 'View and track account deletion requests',
                icon: Icons.delete_outline,
                color: const Color(0xFF8B0000),

                onTap: () => _openPage(const DeletionRequestsScreen()),
              ),

              const SizedBox(height: 15),

              // ==========================
              // SECURITY NOTICE
              // ==========================
              Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: const Color(0xFFF4DFC5),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Row(
                  children: [
                    Icon(Icons.verified_user, color: brown),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Authorized administrator access only. '
                        'Account actions are protected by '
                        'Firebase Security Rules.',
                        style: TextStyle(color: brown, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
