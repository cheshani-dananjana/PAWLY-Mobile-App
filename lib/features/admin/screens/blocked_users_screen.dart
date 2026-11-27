import 'package:flutter/material.dart';

import 'manage_users_screen.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ManageUsersScreen(blockedOnly: true);
  }
}
