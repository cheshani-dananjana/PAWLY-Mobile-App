import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/screens/login_screen.dart';
import '../services/admin_service.dart';
import 'manage_users_screen.dart';
import 'blocked_users_screen.dart';
import 'manage_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _service = AdminService();

  static const Color brown = Color(0xFF4A2915);
  static const Color darkBrown = Color(0xFF251605);
  static const Color orange = Color(0xFFBF5700);
  static const Color cream = Color(0xFFFFF7EC);

  late Future<List<int>> _stats;
  late Future<int> _reportCount;

  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();

    _stats = _loadStats();
    _reportCount = _service.getPendingReportsCount();
  }

  Future<List<int>> _loadStats() async {
    return Future.wait([
      _service.getTotalUsers(),
      _service.getTotalPosts(),
      _service.getBlockedUsersCount(),
    ]);
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    final stats = _loadStats();
    final reports = _service.getPendingReportsCount();

    setState(() {
      _stats = stats;
      _reportCount = reports;
    });

    try {
      await Future.wait<Object>([stats, reports]);
    } catch (_) {
      // FutureBuilder displays errors.
    }
  }

  Future<void> _openScreen(Widget screen) async {
    try {
      await _service.checkAdminAccess();

      if (!mounted) return;

      await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

      if (mounted) {
        await _refresh();
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrator access denied.')),
      );
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _loggingOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4DFC5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8B9A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: orange, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: darkBrown,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: brown, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    String title,
    String description,
    IconData icon,
    Widget screen,
  ) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: brown,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(color: darkBrown, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: brown),
        onTap: () => _openScreen(screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.pets),
            SizedBox(width: 10),
            Text('PAWLY Admin'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _loggingOut ? null : _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Welcome, Admin!',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Animal Welfare Management System',
              style: TextStyle(color: brown),
            ),
            const SizedBox(height: 24),
            FutureBuilder<List<int>>(
              future: _stats,
              builder: (context, snapshot) {
                final stats = snapshot.data;
                final loaded =
                    snapshot.connectionState == ConnectionState.done &&
                    !snapshot.hasError &&
                    stats != null;

                return Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _statCard(
                          'Registered Users',
                          loaded ? '${stats[0]}' : '—',
                          Icons.people,
                        ),
                        _statCard(
                          'Animal Posts',
                          loaded ? '${stats[1]}' : '—',
                          Icons.pets,
                        ),
                        FutureBuilder<int>(
                          future: _reportCount,
                          builder: (context, reportSnapshot) {
                            String value = '—';

                            if (reportSnapshot.hasError) {
                              value = 'N/A';
                            } else if (reportSnapshot.connectionState ==
                                    ConnectionState.done &&
                                reportSnapshot.hasData) {
                              value = '${reportSnapshot.data}';
                            }

                            return _statCard(
                              'Pending Reports',
                              value,
                              Icons.flag,
                            );
                          },
                        ),
                        _statCard(
                          'Blocked Users',
                          loaded ? '${stats[2]}' : '—',
                          Icons.person_off,
                        ),
                      ],
                    ),
                    if (snapshot.hasError)
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Unable to load statistics. Retry'),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'Management',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 14),
            _menuCard(
              'Manage Users',
              'View, ban or disable users',
              Icons.manage_accounts,
              const ManageUsersScreen(),
            ),
            _menuCard(
              'Manage Reports',
              'Review and resolve reported posts',
              Icons.flag_outlined,
              const ManageReportsScreen(),
            ),
            _menuCard(
              'Blocked Accounts',
              'Reactivate blocked users',
              Icons.block,
              const BlockedUsersScreen(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loggingOut ? null : _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
