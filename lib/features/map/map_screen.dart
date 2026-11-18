import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBE8BC),
        title: const Text(
          'Nearby Paws',
          style: TextStyle(
            color: Color(0xFF251605),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_rounded,
              size: 80,
              color: Color(0xFFBF5700),
            ),
            SizedBox(height: 16),
            Text(
              'Discover Nearby Animals',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 8),
            Text('Map view will be available here.'),
          ],
        ),
      ),
    );
  }
}
