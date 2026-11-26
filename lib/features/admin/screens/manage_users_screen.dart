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
  static const Color cream = Color(0xFFFFF7EC);

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
        return Colors.green;
      case 'banned':
        return Colors.red;
      case 'disabled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _changeStatus(String uid, String name, String status) async {
    if (_updating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm action'),
        content: Text('Change the account status of $name to $status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(widget.blockedOnly ? 'Blocked Accounts' : 'Manage Users'),
        backgroundColor: brown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _search = value.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (_updating) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Unable to load users. Check permissions or connection.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.metadata.isFromCache) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((document) {
                  final data = document.data();

                  final name = '${data['full_name'] ?? ''}'.toLowerCase();

                  final email = '${data['email'] ?? ''}'.toLowerCase();

                  return name.contains(_search) || email.contains(_search);
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final document = users[index];
                    final data = document.data();

                    final name = '${data['full_name'] ?? 'Unknown'}';

                    final email = '${data['email'] ?? 'No email'}';

                    final role = '${data['role'] ?? 'unknown'}';

                    final status = '${data['account_status'] ?? 'unknown'}';

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: brown,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(email),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              role == 'admin'
                                  ? 'Role: Administrator'
                                  : 'Role: $role',
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Status: ${status.toUpperCase()}',
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (role == 'user') ...[
                              const Divider(),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (status != 'banned')
                                    ElevatedButton(
                                      onPressed: _updating
                                          ? null
                                          : () => _changeStatus(
                                              document.id,
                                              name,
                                              'banned',
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Ban'),
                                    ),
                                  if (status != 'disabled')
                                    ElevatedButton(
                                      onPressed: _updating
                                          ? null
                                          : () => _changeStatus(
                                              document.id,
                                              name,
                                              'disabled',
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Disable'),
                                    ),
                                  if (status != 'active')
                                    ElevatedButton(
                                      onPressed: _updating
                                          ? null
                                          : () => _changeStatus(
                                              document.id,
                                              name,
                                              'active',
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Reactivate'),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
