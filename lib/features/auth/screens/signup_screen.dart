import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
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

  void _signUp() async {
    String name = _fullNameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);

    String phone = _phoneController.text.trim();

    String? error = await _authService.signUp(name, email, password, phone);

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Created! You can now log in. 🐾"),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool? obscureText,
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
            fontWeight: FontWeight.w600,
            color: Color(0xFF251605),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? (obscureText ?? true) : false,
            keyboardType: keyboardType,
            style: const TextStyle(color: Color(0xFF251605)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText!
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7DBA7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.pets, size: 70, color: Color(0xFF251605)),
                const SizedBox(height: 10),
                const Text(
                  "PAWLY",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Color(0xFF251605),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Join us in helping paws in need",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF251605),
                  ),
                ),
                const SizedBox(height: 30),

                _buildInputField(
                  label: "Full Name",
                  hint: "Enter your full name",
                  controller: _fullNameController,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: "Email",
                  hint: "Enter your email address",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: "Phone Number",
                  hint: "Enter your phone number",
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: "Password",
                  hint: "Create a password",
                  controller: _passwordController,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: "Confirm Password",
                  hint: "Re-enter your password",
                  controller: _confirmPasswordController,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFFBF5700))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBF5700),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _signUp,
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Color(0xFF251605), fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          color: Color(0xFFBF5700),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
