import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBE8BC),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF251605),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_rounded,
              size: 85,
              color: Color(0xFFBF5700),
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to PAWLY',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
