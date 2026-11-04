import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/animals/create_post_screen.dart'; // 1. Add your screen import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAWLY',
      debugShowCheckedModeBanner: false,
      // Apply your global theme here if configured:
      // theme: buildPawlyTheme(), 
      
      // 2. Set your working screen as the starting view:
      home: const CreatePostScreen(), 
    );
  }
}