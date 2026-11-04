import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

/// PAWLY global theme colors
class PawlyColors {
  static const Color burntOrange = Color(0xFFBF5700);
  static const Color espressoBrown = Color(0xFF251605);
  static const Color softCream = Color(0xFFF7DBA7);
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImage;
  String _postType = 'Stray';
  bool _isPublishing = false;

  // Post types with a matching emoji for extra cuteness
  static const Map<String, String> _postTypes = {
    'Stray': '🐾',
    'Lost': '🔍',
    'Adoption': '🏠',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      _showSnack('Could not open the photo picker. Please try again.');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PawlyColors.softCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: PawlyColors.espressoBrown.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: PawlyColors.burntOrange),
                  title: const Text('Choose from gallery',
                      style: TextStyle(
                          color: PawlyColors.espressoBrown,
                          fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded,
                      color: PawlyColors.burntOrange),
                  title: const Text('Take a photo',
                      style: TextStyle(
                          color: PawlyColors.espressoBrown,
                          fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Future<void> _publishPost() async {
    FocusScope.of(context).unfocus();

    if (_selectedImage == null) {
      _showSnack('Please add a photo of the animal first 🐶');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);

    // TODO (Phase 3): Upload _selectedImage to Firebase Storage, then save
    // _postType, _nameController.text, _locationController.text and
    // _descriptionController.text to Firestore.
    await Future.delayed(const Duration(milliseconds: 1200)); // placeholder

    if (!mounted) return;
    setState(() => _isPublishing = false);
    _showSnack('Post published! Thanks for helping 🧡');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: PawlyColors.espressoBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawlyColors.softCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: PawlyColors.espressoBrown),
        title: const Text(
          'Add Animal Post',
          style: TextStyle(
            color: PawlyColors.espressoBrown,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildPhotoCard(),
                const SizedBox(height: 24),
                _buildSectionLabel('What kind of post is this?', 350),
                const SizedBox(height: 10),
                _buildPostTypeChips(),
                const SizedBox(height: 24),
                _buildDetailsCard(),
                const SizedBox(height: 28),
                _buildPublishButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI sections
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      children: [
        // Gently floating paw
        const Icon(Icons.pets_rounded, size: 40, color: PawlyColors.burntOrange)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
                begin: 0,
                end: -6,
                duration: 1200.ms,
                curve: Curves.easeInOut)
            .rotate(begin: -0.03, end: 0.03, duration: 1200.ms),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Help an animal find\ntheir way home 🧡',
            style: TextStyle(
              color: PawlyColors.espressoBrown,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.1, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildPhotoCard() {
    final card = _BouncyTap(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: PawlyColors.burntOrange, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: PawlyColors.burntOrange.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: PawlyColors.burntOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 20),
                    ).animate().scale(
                        duration: 400.ms, curve: Curves.elasticOut),
                  ),
                ],
              ).animate(key: ValueKey(_selectedImage!.path)).fadeIn().scale(
                  begin: const Offset(0.95, 0.95),
                  curve: Curves.easeOutBack)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: PawlyColors.softCream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_rounded,
                        size: 40, color: PawlyColors.burntOrange),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.08, 1.08),
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap to add a cute photo',
                    style: TextStyle(
                      color: PawlyColors.espressoBrown,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gallery or camera',
                    style: TextStyle(
                      color: PawlyColors.espressoBrown.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );

    // Outer: entrance animation. Inner: endless soft floating.
    return card
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
            begin: 0,
            end: -4,
            duration: 2000.ms,
            curve: Curves.easeInOut)
        .animate()
        .fadeIn(delay: 100.ms, duration: 500.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildSectionLabel(String text, int delayMs) {
    return Text(
      text,
      style: const TextStyle(
        color: PawlyColors.espressoBrown,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ).animate().fadeIn(delay: delayMs.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildPostTypeChips() {
    final entries = _postTypes.entries.toList();

    return Row(
      children: List.generate(entries.length, (i) {
        final type = entries[i].key;
        final emoji = entries[i].value;
        final isSelected = _postType == type;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == entries.length - 1 ? 0 : 10),
            child: _BouncyTap(
              onTap: () => setState(() => _postType = type),
              child: AnimatedContainer(
                duration: 250.ms,
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? PawlyColors.burntOrange : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PawlyColors.burntOrange,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: PawlyColors.burntOrange
                                .withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : PawlyColors.espressoBrown,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: (400 + i * 100).ms)
            .slideY(begin: 0.4, end: 0, curve: Curves.easeOutBack);
      }),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: PawlyColors.burntOrange.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          _buildField(
            controller: _nameController,
            label: 'Animal Name (or "Unknown")',
            icon: Icons.pets_rounded,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Type a name, or "Unknown"'
                : null,
          ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.15, end: 0),
          const SizedBox(height: 16),
          _buildField(
            controller: _locationController,
            label: 'Location Found/Lost',
            icon: Icons.location_on_rounded,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Where was the animal?'
                : null,
          ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.15, end: 0),
          const SizedBox(height: 16),
          _buildField(
            controller: _descriptionController,
            label: 'Description & Condition',
            icon: Icons.favorite_rounded,
            maxLines: 4,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Tell us a little about the animal'
                : null,
          ).animate().fadeIn(delay: 900.ms).slideX(begin: 0.15, end: 0),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      cursorColor: PawlyColors.burntOrange,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
          color: PawlyColors.espressoBrown, fontWeight: FontWeight.w500),
      decoration: _buildInputDecoration(label, icon),
    );
  }

  Widget _buildPublishButton() {
    return _BouncyTap(
      onTap: _isPublishing ? null : _publishPost,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: PawlyColors.burntOrange,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: PawlyColors.burntOrange.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isPublishing
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pets_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Publish Post',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      )
          // Sparkle that sweeps across the button every few seconds
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            delay: 2500.ms,
            duration: 1200.ms,
            color: Colors.white.withValues(alpha: 0.3),
          ),
    )
        .animate()
        .fadeIn(delay: 1000.ms)
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          duration: 700.ms,
          curve: Curves.elasticOut,
        );
  }

  // Helper method to keep text fields styled consistently
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: PawlyColors.burntOrange),
      floatingLabelStyle: const TextStyle(
          color: PawlyColors.burntOrange, fontWeight: FontWeight.w700),
      prefixIcon: Icon(icon, color: PawlyColors.burntOrange),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder:
          border(PawlyColors.burntOrange.withValues(alpha: 0.5), 1.5),
      focusedBorder: border(PawlyColors.burntOrange, 2.5),
      errorBorder: border(Colors.red.shade700, 1.5),
      focusedErrorBorder: border(Colors.red.shade700, 2.5),
      errorStyle: TextStyle(
          color: Colors.red.shade800, fontWeight: FontWeight.w600),
    );
  }
}

/// A tap wrapper that squishes down when pressed and springs back with a
/// bouncy, pet-like motion. Reuse it for any tappable card or button.
class _BouncyTap extends StatefulWidget {
  const _BouncyTap({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<_BouncyTap> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: _pressed ? 100.ms : 500.ms,
        curve: _pressed ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}
