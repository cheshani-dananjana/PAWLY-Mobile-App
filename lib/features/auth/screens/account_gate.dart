import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../home/home_feed_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import 'login_screen.dart';

class AccountGate extends StatefulWidget {
  const AccountGate({super.key});

  @override
  State<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<AccountGate> with WidgetsBindingObserver {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  bool _allowed = false;
  bool _busy = true;
  String _role = '';
  bool _checking = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _verify();
  }

  Future<void> _verify() async {
    if (_checking || _blocked) return;

    _checking = true;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _deny();
        return;
      }

      await user.reload();

      if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
        _deny();
        return;
      }

      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final doc = await ref.get(const GetOptions(source: Source.server));

      if (!mounted || _blocked) return;

      if (!_accept(doc.data())) {
        _deny();
        return;
      }

      await _sub?.cancel();

      if (!mounted || _blocked) return;

      _sub = ref.snapshots(includeMetadataChanges: true).listen((snapshot) {
        if (!mounted || _blocked) return;

        if (snapshot.metadata.isFromCache) return;

        if (!_accept(snapshot.data())) {
          _deny();
        }
      }, onError: (Object error) => _deny());
    } catch (_) {
      _deny();
    } finally {
      _checking = false;
    }
  }

  bool _accept(Map<String, dynamic>? data) {
    final role = data?['role'];

    if (data?['account_status'] != 'active' ||
        !['admin', 'user'].contains(role)) {
      return false;
    }

    final roleChanged = _role.isNotEmpty && _role != role;

    setState(() {
      _role = role as String;
      _allowed = true;
      _busy = false;
    });

    if (roleChanged) {
      _closeRestrictedRoutes();
    }

    return true;
  }

  void _closeRestrictedRoutes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  void _deny() {
    if (!mounted || _blocked) return;

    _blocked = true;

    setState(() {
      _allowed = false;
      _busy = false;
    });

    _closeRestrictedRoutes();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verify();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed) {
      if (_role == 'admin') {
        return const AdminDashboardScreen(key: ValueKey('admin'));
      }

      return HomeFeedScreen(key: ValueKey(_role));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8ED),
      body: Center(
        child: _busy
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.gpp_bad_outlined,
                    size: 65,
                    color: Colors.red,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Account blocked or unable to '
                      'verify. Please contact support '
                      'or sign in again.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      if (!context.mounted) return;

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
      ),
    );
  }
}
