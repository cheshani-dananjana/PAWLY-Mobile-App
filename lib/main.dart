import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // 1. Ensure Flutter engine is ready before Firebase starts
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Firebase
  await Firebase.initializeApp();

  // 3. Run the App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAWLY',
      debugShowCheckedModeBanner: false,
      theme: buildPawlyTheme(), // Using your Burnt Orange & Cream theme!
      home: const Scaffold(
        body: Center(
          child: Text(
            'PAWLY - Firebase Connected! 🐾',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}