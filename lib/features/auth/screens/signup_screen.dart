import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _entryController;
  late AnimationController _floatController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // PAWLY COLOURS

  static const Color burntOrange = Color(0xFFBF5700);
  static const Color brightOrange = Color(0xFFD96B12);
  static const Color deepOrange = Color(0xFF9E4000);

  static const Color chocolateBrown = Color(0xFF4A2915);
  static const Color darkBrown = Color(0xFF251605);
  static const Color deepBrown = Color(0xFF351C0C);

  static const Color warmCream = Color(0xFFF7DBA7);
  static const Color softPeach = Color(0xFFF4C89E);
  static const Color inputCream = Color(0xFFFFF7EC);
  static const Color borderPeach = Color(0xFFE8B9A5);

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();

    _entryController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _entryController.dispose();
    _floatController.dispose();

    super.dispose();
  }

  // CUSTOM MESSAGE

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFB83232) : chocolateBrown,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isError ? Colors.white24 : burntOrange,
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.pets_rounded,
                color: warmCream,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SIGN UP FUNCTION

  Future<void> _signUp() async {
    if (_isLoading) return;

    String name = _fullNameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage("Please fill in all required fields", isError: true);
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showMessage("Please enter a valid email address", isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? error = await _authService.signUp(name, email, password, phone);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (error != null) {
        _showMessage(error, isError: true);
      } else {
        _showMessage("Account Created! You can now log in. 🐾");

        await Future.delayed(const Duration(milliseconds: 900));

        if (!mounted) return;

        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showMessage("Something went wrong. Please try again.", isError: true);
    }
  }

  // FLOATING PAW PRINTS

  Widget _animatedPaw({
    required double size,
    required double rotation,
    required Color color,
    required double phase,
  }) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final double progress = _floatController.value * 2 * math.pi + phase;

        final double offsetY = math.sin(progress) * 10;
        final double offsetX = math.cos(progress) * 4;
        final double opacity = 0.75 + math.sin(progress) * 0.15;

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Transform.rotate(
            angle: rotation + math.sin(progress) * 0.04,
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      },
      child: Icon(Icons.pets_rounded, size: size, color: color),
    );
  }

  // LOGO

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        height: 76,
        width: 76,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [brightOrange, burntOrange, chocolateBrown, darkBrown],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: chocolateBrown.withOpacity(0.24),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF713509), Color(0xFF351C0C), Color(0xFF251605)],
            ),
          ),
          child: const Icon(Icons.pets_rounded, color: warmCream, size: 43),
        ),
      ),
    );
  }

  // INPUT FIELD

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: darkBrown,
          ),
        ),

        const SizedBox(height: 5),

        Container(
          height: 46,
          decoration: BoxDecoration(
            color: inputCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderPeach, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: chocolateBrown.withOpacity(0.045),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && obscureText,
            style: const TextStyle(
              color: darkBrown,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: darkBrown.withOpacity(0.38),
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: chocolateBrown, size: 20),
              prefixIconConstraints: const BoxConstraints(minWidth: 43),
              suffixIcon: isPassword
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                      onPressed: onToggleVisibility,
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: chocolateBrown.withOpacity(0.65),
                        size: 19,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SIGN UP BUTTON

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE98226),
              Color(0xFFD96B12),
              Color(0xFFAC4A08),
              Color(0xFF713509),
              Color(0xFF351C0C),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: chocolateBrown.withOpacity(0.24),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    height: 21,
                    width: 21,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    key: ValueKey('signup'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // SIGNUP CARD

  Widget _buildSignupCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0D9), Color(0xFFFCE5C5), Color(0xFFFFEBD2)],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: borderPeach, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: chocolateBrown.withOpacity(0.11),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Create Account",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: deepBrown,
              ),
            ),
          ),

          const SizedBox(height: 3),

          Center(
            child: Text(
              "Start your PAWLY journey today!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: darkBrown.withOpacity(0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 13),

          // FULL NAME
          _buildInputField(
            label: "Full Name",
            hint: "Enter your full name",
            controller: _fullNameController,
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 9),

          // EMAIL
          _buildInputField(
            label: "Email Address",
            hint: "Enter your email address",
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 9),

          // PHONE
          _buildInputField(
            label: "Phone Number",
            hint: "Enter your phone number",
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 9),

          // PASSWORD
          _buildInputField(
            label: "Password",
            hint: "Create a password",
            controller: _passwordController,
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),

          const SizedBox(height: 9),

          // CONFIRM PASSWORD
          _buildInputField(
            label: "Confirm Password",
            hint: "Re-enter your password",
            controller: _confirmPasswordController,
            icon: Icons.verified_user_outlined,
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),

          const SizedBox(height: 15),

          // CREATE ACCOUNT BUTTON
          _buildSignupButton(),

          const SizedBox(height: 12),

          // DIVIDER
          Row(
            children: [
              Expanded(child: Divider(color: borderPeach, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Text(
                  "OR",
                  style: TextStyle(
                    fontSize: 11,
                    color: chocolateBrown.withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(child: Divider(color: borderPeach, thickness: 1)),
            ],
          ),

          const SizedBox(height: 11),

          // LOGIN NAVIGATION
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  "Already have an account? ",
                  style: TextStyle(
                    fontSize: 13,
                    color: darkBrown.withOpacity(0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Log In",
                  style: TextStyle(
                    fontSize: 14,
                    color: chocolateBrown,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                    decorationColor: chocolateBrown,
                    decorationThickness: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // MAIN BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmCream,

      body: Stack(
        children: [
          // BACKGROUND GRADIENT

          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE8C7),
                    warmCream,
                    softPeach,
                    Color(0xFFEBC1A4),
                  ],
                  stops: [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
          ),

          // DECORATIVE CIRCLES
          Positioned(
            bottom: -85,
            left: -75,
            child: Container(
              height: 230,
              width: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: burntOrange.withOpacity(0.10),
              ),
            ),
          ),

          Positioned(
            top: 300,
            left: -95,
            child: Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brightOrange.withOpacity(0.055),
              ),
            ),
          ),

          Positioned(
            bottom: 300,
            right: -100,
            child: Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chocolateBrown.withOpacity(0.045),
              ),
            ),
          ),

          // ANIMATED PAW PRINTS
          Positioned(
            top: 35,
            left: 18,
            child: _animatedPaw(
              size: 39,
              rotation: -0.35,
              color: chocolateBrown.withOpacity(0.23),
              phase: 0,
            ),
          ),

          Positioned(
            top: 105,
            right: 25,
            child: _animatedPaw(
              size: 48,
              rotation: 0.35,
              color: burntOrange.withOpacity(0.25),
              phase: 1.2,
            ),
          ),

          Positioned(
            top: 175,
            left: 75,
            child: _animatedPaw(
              size: 23,
              rotation: 0.25,
              color: chocolateBrown.withOpacity(0.15),
              phase: 2.1,
            ),
          ),

          Positioned(
            top: 230,
            right: 65,
            child: _animatedPaw(
              size: 27,
              rotation: -0.3,
              color: burntOrange.withOpacity(0.19),
              phase: 3.2,
            ),
          ),

          Positioned(
            top: 350,
            left: 15,
            child: _animatedPaw(
              size: 34,
              rotation: 0.4,
              color: deepBrown.withOpacity(0.17),
              phase: 2.7,
            ),
          ),

          Positioned(
            top: 420,
            right: 20,
            child: _animatedPaw(
              size: 40,
              rotation: -0.3,
              color: burntOrange.withOpacity(0.20),
              phase: 4.1,
            ),
          ),

          Positioned(
            top: 510,
            left: 55,
            child: _animatedPaw(
              size: 22,
              rotation: -0.4,
              color: chocolateBrown.withOpacity(0.15),
              phase: 5.0,
            ),
          ),

          Positioned(
            top: 570,
            right: 55,
            child: _animatedPaw(
              size: 25,
              rotation: 0.3,
              color: deepBrown.withOpacity(0.16),
              phase: 0.8,
            ),
          ),

          Positioned(
            bottom: 115,
            right: 22,
            child: _animatedPaw(
              size: 35,
              rotation: 0.25,
              color: chocolateBrown.withOpacity(0.20),
              phase: 3.8,
            ),
          ),

          Positioned(
            bottom: 190,
            left: 18,
            child: _animatedPaw(
              size: 28,
              rotation: -0.25,
              color: burntOrange.withOpacity(0.19),
              phase: 1.8,
            ),
          ),

          Positioned(
            bottom: 55,
            left: 105,
            child: _animatedPaw(
              size: 23,
              rotation: 0.3,
              color: deepBrown.withOpacity(0.17),
              phase: 4.7,
            ),
          ),

          Positioned(
            bottom: 265,
            right: 105,
            child: _animatedPaw(
              size: 22,
              rotation: -0.2,
              color: burntOrange.withOpacity(0.15),
              phase: 2.4,
            ),
          ),

          // MAIN CONTENT - NO SCROLLING
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 23,
                              vertical: 5,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // LOGO

                                _buildLogo(),

                                const SizedBox(height: 5),

                                // APP NAME
                                const Text(
                                  "PAWLY",
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    color: deepBrown,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                // TAGLINE
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [chocolateBrown, deepBrown],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Text(
                                    "Join us in helping paws in need",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: warmCream,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 13),

                                // SIGNUP CARD
                                _buildSignupCard(),

                                const SizedBox(height: 12),

                                // FOOTER
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      color: burntOrange,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Made with love for every pet",
                                      style: TextStyle(
                                        color: deepBrown.withOpacity(0.8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
