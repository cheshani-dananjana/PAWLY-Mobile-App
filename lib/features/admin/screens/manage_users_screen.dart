import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/admin_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key, this.blockedOnly = false});

  final bool blockedOnly;

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AdminService _service = AdminService();

  static const Color brown = Color(0xFF4A2915);
  static const Color cream = Color(0xFFFCE8C9);

  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  String _search = '';
  bool _updating = false;

  @override
  void initState() {
    super.initState();

    _stream = widget.blockedOnly
        ? _service.getBlockedUsers()
        : _service.getUsers();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF287044);
      case 'banned':
        return const Color(0xFFAA3636);
      case 'disabled':
        return const Color(0xFFA45100);
      default:
        return const Color(0xFF75665C);
    }
  }

  Future<void> _changeStatus(String uid, String name, String status) async {
    if (_updating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF6E9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm action', style: TextStyle(color: brown)),
        content: Text('Change the account status of $name to $status?'),
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
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);

    try {
      await _service.updateAccountStatus(uid, status);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account status updated to $status.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update account status.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  static const Color muted = Color(0xFF805237);
  static const Color peach = Color(0xFFF0C9AE);

  Widget _action(
    String label,
    IconData icon,
    Color color,
    VoidCallback action,
  ) {
    return ElevatedButton.icon(
      onPressed: _updating ? null : action,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.10),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _userCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final name = '${data['full_name'] ?? 'Unknown'}';
    final email = '${data['email'] ?? 'No email'}';
    final role = '${data['role'] ?? 'unknown'}';
    final status = '${data['account_status'] ?? 'unknown'}';
    final color = _statusColor(status);
    return TweenAnimationBuilder<double>(
      key: ValueKey(document.id),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF6E9), Color(0xFFFFEBD6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: peach),
          boxShadow: [
            BoxShadow(
              color: brown.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5D8B9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    role == 'admin'
                        ? Icons.admin_panel_settings_rounded
                        : Icons.person_rounded,
                    color: brown,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: brown,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  role == 'admin' ? 'Administrator' : 'Role: $role',
                  muted,
                  Icons.badge_outlined,
                ),
                _chip(status.toUpperCase(), color, Icons.circle),
              ],
            ),
            if (role == 'user') ...[
              const Divider(height: 26, color: peach),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (status != 'banned')
                    _action(
                      'Ban',
                      Icons.block,
                      const Color(0xFFAA3636),
                      () => _changeStatus(document.id, name, 'banned'),
                    ),
                  if (status != 'disabled')
                    _action(
                      'Disable',
                      Icons.pause_circle_outline,
                      const Color(0xFFA45100),
                      () => _changeStatus(document.id, name, 'disabled'),
                    ),
                  if (status != 'active')
                    _action(
                      'Reactivate',
                      Icons.check_circle_outline,
                      const Color(0xFF287044),
                      () => _changeStatus(document.id, name, 'active'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(
          widget.blockedOnly ? 'Blocked Accounts' : 'Manage Users',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: cream,
        foregroundColor: brown,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
          fit: StackFit.expand,
          children: [
            const IgnorePointer(
              child: Stack(
                children: [
                  Positioned(top: 8, right: 14, child: _UsersPaw(size: 46)),
                  Positioned(
                    top: 250,
                    left: -10,
                    child: _UsersPaw(size: 52, angle: -0.4, phase: 0.3),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 10,
                    child: _UsersPaw(size: 70, angle: 0.5, phase: 0.6),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.blockedOnly
                              ? 'Account safety'
                              : 'PAWLY community',
                          style: const TextStyle(
                            color: brown,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage accounts with care.',
                          style: TextStyle(color: muted),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          onChanged: (value) => setState(
                            () => _search = value.toLowerCase().trim(),
                          ),
                          style: const TextStyle(color: brown),
                          decoration: InputDecoration(
                            hintText: 'Search by name or email',
                            hintStyle: const TextStyle(
                              color: muted,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: muted,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF6E9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: peach),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: muted,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_updating)
                    const LinearProgressIndicator(color: Color(0xFFC65A00)),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Unable to load users. Check permissions or connection.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: brown),
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData ||
                            snapshot.data!.metadata.isFromCache) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFC65A00),
                            ),
                          );
                        }
                        final users = snapshot.data!.docs.where((document) {
                          final data = document.data();
                          final name = '${data['full_name'] ?? ''}'
                              .toLowerCase();
                          final email = '${data['email'] ?? ''}'.toLowerCase();
                          return name.contains(_search) ||
                              email.contains(_search);
                        }).toList();
                        if (users.isEmpty) {
                          return const Center(
                            child: Text(
                              'No users found.',
                              style: TextStyle(color: brown),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                          itemCount: users.length,
                          itemBuilder: (context, index) =>
                              _userCard(users[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersPaw extends StatefulWidget {
  const _UsersPaw({required this.size, this.angle = 0.25, this.phase = 0.0});
  final double size, angle, phase;

  @override
  State<_UsersPaw> createState() => _UsersPawState();
}

class _UsersPawState extends State<_UsersPaw>
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
