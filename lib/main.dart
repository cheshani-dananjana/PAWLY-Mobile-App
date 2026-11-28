import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'features/auth/screens/splash_screen.dart';
import 'firebase_options.dart';

const bool useEmulator = bool.fromEnvironment(
  'USE_EMULATOR',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (useEmulator) {
    final bool isAndroid =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android;

    final String host =
        isAndroid ? '10.0.2.2' : '127.0.0.1';

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'dummy-api-key',
        appId: isAndroid
            ? '1:123456789012:android:0000000000000000000000'
            : '1:123456789012:web:0000000000000000000000',
        messagingSenderId: '123456789012',
        projectId: 'demo-pawly',
        authDomain: 'demo-pawly.firebaseapp.com',
        storageBucket: 'demo-pawly.appspot.com',
      ),
    );

    if (Firebase.app().options.projectId != 'demo-pawly') {
      throw StateError(
        'Invalid Firebase project for local testing.',
      );
    }

    await FirebaseAuth.instance.useAuthEmulator(
      host,
      9099,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );

    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      8080,
    );

    debugPrint('PAWLY: LOCAL EMULATOR MODE');
    debugPrint(
      'Firebase project: ${Firebase.app().options.projectId}',
    );
    debugPrint('Emulator host: $host');
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('PAWLY: SHARED FIREBASE MODE');
  }

  final User? savedUser =
      await FirebaseAuth.instance.authStateChanges().first;

  runApp(
    MyApp(isSignedIn: savedUser != null),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.isSignedIn,
  });

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
      
home: SplashScreen(isSignedIn: isSignedIn),

    );
  }
}
