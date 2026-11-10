import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

// Mouse, Touch, Trackpad Swiping
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
  late final AnimationController _pawController;
  late final Animation<double> _pawAnimation;

  Timer? _autoPageTimer;

  int _currentPage = 1000;
  bool _manualDrag = false;

  final Set<int> _activePointers = <int>{};

  // PAWLY COLOUR PALETTE
  static const Color burntOrange = Color(0xFFBF5700);
  static const Color brightOrange = Color(0xFFD96B12);

  static const Color chocolateBrown = Color(0xFF4A2915);
  static const Color darkBrown = Color(0xFF251605);
  static const Color deepBrown = Color(0xFF351C0C);

  static const Color warmCream = Color(0xFFF7DBA7);
  static const Color softPeach = Color(0xFFF4C89E);
  static const Color lightPeach = Color(0xFFFFF0D9);

  // PET IMAGES
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
      viewportFraction: 0.62,
    );

    // PAW ICON ZOOM ANIMATION
    _pawController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pawAnimation = Tween<double>(
      begin: 0.96,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pawController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAutoPage();
      }
    });
  }

  // AUTO CAROUSEL
  void _startAutoPage() {
    _autoPageTimer?.cancel();

    if (!mounted || _manualDrag || _activePointers.isNotEmpty) {
      return;
    }

    _autoPageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted ||
          !_pageController.hasClients ||
          _manualDrag ||
          _activePointers.isNotEmpty) {
        return;
      }

      if (_pageController.position.isScrollingNotifier.value) {
        return;
      }

      if (ModalRoute.of(context)?.isCurrent == false) {
        return;
      }

      final nextPage =
          (_pageController.page ?? _currentPage.toDouble()).round() + 1;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
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

    if (_activePointers.isEmpty) {
      _startAutoPage();
    }
  }

  // MANUAL DRAG
  void _onDragStart(DragStartDetails details) {
    _manualDrag = true;
    _autoPageTimer?.cancel();

    if (_pageController.hasClients) {
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

    if (mounted) {
      _startAutoPage();
    }
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

  // NAVIGATION
  void _openSignup() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  void _openLogin() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _autoPageTimer?.cancel();
    _pageController.dispose();
    _pawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBrown,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenHeight = constraints.maxHeight;
            final double screenWidth = constraints.maxWidth;

            final bool compact = screenHeight < 760;
            final bool veryCompact = screenHeight < 650;

            final double headingSize = veryCompact
                ? 27
                : compact
                ? 32
                : 37;

            final double descriptionSize = veryCompact ? 13 : 15;
            final double horizontalPadding = screenWidth < 360 ? 20 : 28;
            final double buttonHeight = veryCompact ? 48 : 54;
            final double logoOuterSize = veryCompact ? 85 : 105;
            final double logoIconSize = veryCompact ? 46 : 58;

            return Column(
              children: [
                SizedBox(height: veryCompact ? 5 : 12),

                // ANIMATED PAW ICON
                AnimatedBuilder(
                  animation: _pawAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pawAnimation.value,
                      child: Container(
                        height: logoOuterSize,
                        width: logoOuterSize,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              brightOrange,
                              burntOrange,
                              chocolateBrown,
                              darkBrown,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF713509),
                                Color(0xFF351C0C),
                                Color(0xFF251605),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            Icons.pets_rounded,
                            size: logoIconSize,
                            color: warmCream,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: veryCompact ? 9 : 12),

                // PAWLY BRAND NAME
                ShaderMask(
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
                      fontSize: veryCompact
                          ? 54
                          : compact
                          ? 62
                          : 70,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: veryCompact ? 8 : 13),

                // MAIN HEADING
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Text(
                        'Adopt Your',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: headingSize,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          color: lightPeach,
                        ),
                      ),

                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [warmCream, softPeach, brightOrange],
                          ).createShader(bounds);
                        },
                        child: Text(
                          'New Best Friend',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: headingSize,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      SizedBox(height: veryCompact ? 4 : 7),

                      Text(
                        'Find loving, adoptable pets and\n'
                        'give them a forever home.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: descriptionSize,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: warmCream.withOpacity(0.82),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: veryCompact ? 4 : 8),

                // PET IMAGE CAROUSEL
                Expanded(
                  child: Center(
                    child: Column(
                      children: [
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.depth != 0) {
                                return false;
                              }

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
                                pageSnapping: false,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final String imageAsset =
                                      _cutePetImages[index %
                                          _cutePetImages.length];

                                  return AnimatedBuilder(
                                    animation: _pageController,
                                    builder: (context, child) {
                                      double value = 0;

                                      if (_pageController.hasClients) {
                                        value =
                                            _pageController
                                                .position
                                                .haveDimensions
                                            ? index -
                                                  (_pageController.page ??
                                                      _currentPage.toDouble())
                                            : (index - _currentPage).toDouble();
                                      }

                                      final double scale =
                                          (1 - value.abs() * 0.20).clamp(
                                            0.78,
                                            1.0,
                                          );

                                      final double opacity =
                                          (1 - value.abs() * 0.42).clamp(
                                            0.5,
                                            1.0,
                                          );

                                      return Transform.scale(
                                        scale: scale,
                                        child: Opacity(
                                          opacity: opacity,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 43,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  lightPeach,
                                                  brightOrange,
                                                  chocolateBrown,
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.30),
                                                  blurRadius: 14,
                                                  offset: const Offset(0, 7),
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(27),
                                                child: Stack(
                                                  children: [
                                                    // PET PHOTO
                                                    Positioned.fill(
                                                      child: Image.asset(
                                                        imageAsset,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return Container(
                                                                color:
                                                                    chocolateBrown,
                                                                child: const Icon(
                                                                  Icons
                                                                      .pets_rounded,
                                                                  size: 55,
                                                                  color:
                                                                      lightPeach,
                                                                ),
                                                              );
                                                            },
                                                      ),
                                                    ),

                                                    // DARK IMAGE GRADIENT
                                                    Positioned.fill(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                            colors: [
                                                              Colors.black
                                                                  .withOpacity(
                                                                    0.08,
                                                                  ),
                                                              Colors
                                                                  .transparent,
                                                              darkBrown
                                                                  .withOpacity(
                                                                    0.48,
                                                                  ),
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
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: veryCompact ? 3 : 7),

                        // CAROUSEL INDICATORS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_cutePetImages.length, (
                            index,
                          ) {
                            final bool selected =
                                (_currentPage % _cutePetImages.length) == index;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 7,
                              width: selected ? 24 : 7,
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? const LinearGradient(
                                        colors: [warmCream, brightOrange],
                                      )
                                    : null,
                                color: selected
                                    ? null
                                    : warmCream.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }),
                        ),

                        SizedBox(height: veryCompact ? 4 : 8),
                      ],
                    ),
                  ),
                ),

                // BOTTOM ACTION AREA
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    3,
                    horizontalPadding,
                    veryCompact ? 3 : 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // GET STARTED BUTTON - CLEAN BORDER WITHOUT GLOW
                      Container(
                        width: double.infinity,
                        height: buttonHeight,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE98226), // Bright Warm Orange (Left)
                              Color(0xFFBF5700), // Burnt Orange
                              Color(0xFF713509), // Chocolate Brown
                              Color(0xFF4A1E05), // Deep Warm Brown (Right)
                            ],
                            stops: [0.0, 0.35, 0.70, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: warmCream.withOpacity(
                              0.65,
                            ), // Bright outline for visibility
                            width: 1.5,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _openSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            minimumSize: Size(double.infinity, buttonHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: GoogleFonts.nunito(
                                  fontSize: veryCompact ? 16 : 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Icon(Icons.arrow_forward_rounded, size: 21),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: veryCompact ? 8 : 13),

                      // SIGN IN SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Already have an account? ',
                              style: GoogleFonts.nunito(
                                color: warmCream.withOpacity(0.82),
                                fontSize: veryCompact ? 12 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _openLogin,
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.nunito(
                                color: lightPeach,
                                fontSize: veryCompact ? 13 : 15,
                                fontWeight: FontWeight.w900,
                                decoration: TextDecoration.underline,
                                decorationColor: lightPeach,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
