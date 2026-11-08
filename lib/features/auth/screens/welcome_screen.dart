import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

// Enables Mouse Drag / Touch / Trackpad Swiping
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  Timer? _autoPageTimer;
  int _currentPage = 1000;
  bool _manualDrag = false;
  final Set<int> _activePointers = <int>{};

  // PAWLY Color Palette
  static const Color darkEspresso = Color(0xFF251605);
  static const Color softCream = Color(0xFFF7DBA7);
  static const Color burntOrange = Color(0xFFBF5700);

  // Local Asset Images
  final List<String> _cutePetImages = [
    'assets/images/Pet1.png.png',
    'assets/images/Pet2.png.png',
    'assets/images/Pet3.png.png',
    'assets/images/Pet4.png.png',
    'assets/images/Pet5.png.png',
    'assets/images/Pet6.png.png',
    'assets/images/Pet7.png.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.58,
    );

    // Ambient Glow Light Animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.55).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startAutoPage();
    });
  }

  void _startAutoPage() {
    _autoPageTimer?.cancel();
    if (!mounted || _manualDrag || _activePointers.isNotEmpty) return;
    _autoPageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted ||
          !_pageController.hasClients ||
          _manualDrag ||
          _activePointers.isNotEmpty)
        return;
      if (_pageController.position.isScrollingNotifier.value) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      final nextPage =
          (_pageController.page ?? _currentPage.toDouble()).round() + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    _autoPageTimer?.cancel();
  }

  void _onPointerEnd(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.isEmpty) _startAutoPage();
  }

  void _onDragStart(DragStartDetails details) {
    _manualDrag = true;
    _autoPageTimer?.cancel();
    if (_pageController.hasClients) {
      // Cancel any automatic animation before following the user's finger.
      _pageController.jumpTo(_pageController.offset);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_pageController.hasClients) return;
    final position = _pageController.position;
    final delta = details.primaryDelta ?? 0.0;
    final direction = Directionality.of(context) == TextDirection.rtl
        ? 1.0
        : -1.0;
    final offset = (position.pixels + delta * direction)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    // No fixed animation duration while dragging: movement follows the finger.
    _pageController.jumpTo(offset);
  }

  Future<void> _finishDrag(double fingerVelocity) async {
    _manualDrag = false;
    if (!_pageController.hasClients) {
      _startAutoPage();
      return;
    }
    final page = _pageController.page ?? _currentPage.toDouble();
    final extent =
        _pageController.position.viewportDimension *
        _pageController.viewportFraction;
    if (extent <= 0) {
      _startAutoPage();
      return;
    }
    final direction = Directionality.of(context) == TextDirection.rtl
        ? 1.0
        : -1.0;
    final velocity = fingerVelocity * direction;
    var target = page.round();
    if (velocity.abs() >= 300) {
      // A quick flick advances at least one card; faster flicks can pass two.
      final extra = (velocity.abs() / 1800).floor().clamp(0, 1).toInt();
      target = velocity > 0
          ? page.floor() + 1 + extra
          : page.ceil() - 1 - extra;
    }
    if (target < 0) target = 0;
    final distance = (target - page).abs() * extent;
    final speed = velocity.abs().clamp(450.0, 5000.0).toDouble();
    final milliseconds = (distance / speed * 1000)
        .round()
        .clamp(120, 450)
        .toInt();
    _autoPageTimer?.cancel();
    await _pageController.animateToPage(
      target,
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeOutCubic,
    );
    if (mounted) _startAutoPage();
  }

  Widget _touchAwareCarousel({required Widget child}) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: (details) {
          _finishDrag(details.primaryVelocity ?? 0.0);
        },
        onHorizontalDragCancel: () {
          _finishDrag(0.0);
        },
        child: ScrollConfiguration(behavior: AppScrollBehavior(), child: child),
      ),
    );
  }

  @override
  void dispose() {
    _autoPageTimer?.cancel();
    _pageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: darkEspresso,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 17),

                // Top Paw Icon Header Badge
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: softCream.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: softCream.withOpacity(
                            0.25 + (_glowAnimation.value * 0.3),
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: burntOrange.withOpacity(
                              _glowAnimation.value * 0.4,
                            ),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.pets, size: 34, color: softCream),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Rounded PAWLY wordmark, matching the warm pet-friendly theme.
                Text(
                  'PAWLY',
                  style: GoogleFonts.getFont(
                    'Fredoka',
                    fontSize: 70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.0,
                    height: 1.1,
                    color: softCream,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 10),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                const SizedBox(height: 12),
                Transform.translate(
                  offset: const Offset(0, 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Adopt Your\nNew Best Friend',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.getFont(
                          'Nunito',
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                          color: softCream,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find loving, adoptable pets and\ngive them a forever home.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.getFont(
                          'Nunito',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                          color: softCream.withOpacity(0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 3D Coverflow Carousel Section with Mouse & Touch Dragging
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 300,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.depth != 0) return false;
                              if (notification is ScrollStartNotification &&
                                  notification.dragDetails != null) {
                                _autoPageTimer?.cancel();
                              } else if (notification
                                  is ScrollEndNotification) {
                                _startAutoPage();
                              }
                              return false;
                            },
                            child: _touchAwareCarousel(
                              child: PageView.builder(
                                controller: _pageController,
                                // The outer GestureDetector owns manual dragging.
                                pageSnapping: false,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  String imageAsset =
                                      _cutePetImages[index %
                                          _cutePetImages.length];

                                  return AnimatedBuilder(
                                    animation: _pageController,
                                    builder: (context, child) {
                                      double value = 0.0;
                                      if (_pageController
                                          .position
                                          .haveDimensions) {
                                        value = (index - _pageController.page!);
                                      } else {
                                        value = (index - _currentPage)
                                            .toDouble();
                                      }

                                      // 3D Scale and Opacity Calculation
                                      double scale = (1 - (value.abs() * 0.22))
                                          .clamp(0.78, 1.0);
                                      double opacity =
                                          (1 - (value.abs() * 0.45)).clamp(
                                            0.5,
                                            1.0,
                                          );

                                      return Transform.scale(
                                        scale: scale,
                                        child: Opacity(
                                          opacity: opacity,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: softCream,
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              border: Border.all(
                                                color: burntOrange.withOpacity(
                                                  0.6,
                                                ),
                                                width: 2.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: burntOrange
                                                      .withOpacity(0.25),
                                                  blurRadius: scale > 0.9
                                                      ? 22
                                                      : 8,
                                                  spreadRadius: scale > 0.9
                                                      ? 3
                                                      : 0,
                                                ),
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  blurRadius: 14,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: Image.asset(
                                                      imageAsset,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Container(
                                                            color: darkEspresso,
                                                            child: const Icon(
                                                              Icons.pets,
                                                              color: softCream,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  Positioned.fill(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            burntOrange
                                                                .withOpacity(
                                                                  0.08,
                                                                ),
                                                            Colors.transparent,
                                                            darkEspresso
                                                                .withOpacity(
                                                                  0.65,
                                                                ),
                                                          ],
                                                          stops: const [
                                                            0.0,
                                                            0.5,
                                                            1.0,
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Page Indicator Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_cutePetImages.length, (
                            index,
                          ) {
                            bool isSelected =
                                (_currentPage % _cutePetImages.length) == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 7,
                              width: isSelected ? 22 : 7,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? burntOrange
                                    : softCream.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: burntOrange.withOpacity(0.6),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : [],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(28.0, 10.0, 28.0, 0.0),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: burntOrange.withOpacity(
                                    _glowAnimation.value * 0.7,
                                  ),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: burntOrange,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 3,
                                shadowColor: Colors.transparent,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(
                                      milliseconds: 600,
                                    ),
                                    pageBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                    ) => const SignupScreen(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0, 0.05),
                                                end: Offset.zero,
                                              ).animate(animation),
                                              child: child,
                                            ),
                                          );
                                        },
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(
                                milliseconds: 600,
                              ),
                              pageBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                              ) => const LoginScreen(),
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: softCream,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: softCream,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
