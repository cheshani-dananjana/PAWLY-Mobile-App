import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/account_gate.dart';
import 'firebase_options.dart';

const bool useEmulator = bool.fromEnvironment(
  'USE_EMULATOR',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (useEmulator) {
    // Local Firebase configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'dummy-api-key',
        appId: '1:123456789012:web:0000000000000000000000',
        messagingSenderId: '123456789012',
        projectId: 'demo-pawly',
        authDomain: 'demo-pawly.firebaseapp.com',
        storageBucket: 'demo-pawly.appspot.com',
      ),
    );

    // Emulator host
    final String host =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';

    // Authentication Emulator
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);

    // Firestore Emulator
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );

    debugPrint('PAWLY: LOCAL EMULATOR MODE');
    debugPrint('Firebase project: ${Firebase.app().options.projectId}');
    debugPrint('Emulator host: $host');
  } else {
    // Actual Shared Firebase configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('PAWLY: SHARED FIREBASE MODE');
  }

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
      home: isSignedIn ? const AccountGate() : const SplashScreen(),
    );
  }
}
