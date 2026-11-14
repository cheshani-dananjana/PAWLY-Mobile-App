import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const burntOrange = Color(0xFFBF5700);
  static const brightOrange = Color(0xFFD96B12);
  static const chocolateBrown = Color(0xFF4A2915);
  static const darkBrown = Color(0xFF251605);
  static const deepBrown = Color(0xFF351C0C);
  static const warmCream = Color(0xFFF7DBA7);

  Timer? _timer;

  late final AnimationController _introController;
  late final AnimationController _pawController;

  late final Animation<double> _introScale;
  late final Animation<double> _introFade;
  late final Animation<double> _pawAnimation;

  @override
  void initState() {
    super.initState();

    // Opening pop animation.
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _introScale = Tween<double>(begin: 0.70, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.elasticOut),
    );

    _introFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );

    // Gentle logo zoom, matching the Welcome page.
    _pawController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pawAnimation = Tween<double>(
      begin: 0.96,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pawController, curve: Curves.easeInOut));

    _introController.forward();

    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _introController.dispose();
    _pawController.dispose();
    super.dispose();
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _introFade,
      child: ScaleTransition(
        scale: _introScale,
        child: ScaleTransition(
          scale: _pawAnimation,
          child: Container(
            height: 110,
            width: 110,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [brightOrange, burntOrange, chocolateBrown, darkBrown],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF713509), deepBrown, darkBrown],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.pets_rounded, size: 60, color: warmCream),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBrand() {
    return FadeTransition(
      opacity: _introFade,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF0D9),
              Color(0xFFF7DBA7),
              Color(0xFFF4C89E),
              Color(0xFFD96B12),
            ],
          ).createShader(bounds);
        },
        child: Text(
          'PAWLY',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 5,
            height: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBrown,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Logo stays in the centre of the screen.
          Center(child: _buildLogo()),

          // Brand name near the bottom, above the system navigation.
          Positioned(
            left: 24,
            right: 24,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: _buildBottomBrand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
