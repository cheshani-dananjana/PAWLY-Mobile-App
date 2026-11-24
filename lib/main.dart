import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'features/auth/screens/splash_screen.dart';
import 'features/home/home_feed_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final User? savedUser = await FirebaseAuth.instance.authStateChanges().first;

  runApp(MyApp(isSignedIn: savedUser != null));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isSignedIn});

  final bool isSignedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PAWLY',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF251605),
      ),
      home: isSignedIn ? HomeFeedScreen() : const SplashScreen(),
    );
  }
}
