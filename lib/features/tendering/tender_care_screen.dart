
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'tender_service.dart';

class TenderCareScreen extends StatefulWidget {
  const TenderCareScreen({
    super.key,
    required this.postId,
    required this.animalName,
  });

  final String postId;
  final String animalName;

  @override
  State<TenderCareScreen> createState() => _TenderCareScreenState();
}

class _TenderCareScreenState extends State<TenderCareScreen> {
  static const Color cream = Color(0xFFFDF8ED);
  static const Color orange = Color(0xFFBF5700);
  static const Color espresso = Color(0xFF251605);
  static const Color amber = Color(0xFFF7DCA2);

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  final Set<String> _selectedCareTypes = {};

  File? _evidencePhoto;
  bool _submitting = false;

  static const List<String> _careTypes = [
    'Food',
    'Water',
    'Medical Assistance',
    'Shelter',
  ];

  IconData _careIcon(String type) {
    switch (type) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Water':
        return Icons.water_drop_rounded;
      case 'Medical Assistance':
        return Icons.medical_services_rounded;
      case 'Shelter':
        return Icons.home_rounded;
      default:
        return Icons.pets_rounded;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: espresso,
      ),
    );
  }

  Future<void> _pickEvidencePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: cream,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: orange,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: orange,
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(sheetContext, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (!mounted || picked == null) return;

      setState(() {
        _evidencePhoto = File(picked.path);
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not select photo: $e');
    }
  }

  Future<void> _submitCare() async {
    if (_submitting) return;

    if (_selectedCareTypes.isEmpty) {
      _showMessage('Please select at least one care type.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final photo = _evidencePhoto;

    if (photo == null) {
      _showMessage('Please add an evidence photograph.');
      return;
    }

    setState(() => _submitting = true);

    try {
      await TenderService.submitCare(
        postId: widget.postId,
        careTypes: _selectedCareTypes,
        description: _descriptionController.text.trim(),
        evidencePhoto: photo,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: cream,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: orange),
              SizedBox(width: 8),
              Expanded(child: Text('Care Submitted!')),
            ],
          ),
          content: const Text(
            'Thank you for helping an animal! '
            'Your care record has been submitted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Done',
                style: TextStyle(color: orange),
              ),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to submit care: $e');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: espresso,
        title: const Text(
          'Provide Care',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Helping ${widget.animalName} 🐾',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: espresso,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Small acts of kindness make a big difference.',
                style: TextStyle(
                  color: Color(0xFF8A7A66),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'What care did you provide?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: espresso,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _careTypes.map((type) {
                  final selected =
                      _selectedCareTypes.contains(type);

                  return FilterChip(
                    avatar: Icon(
                      _careIcon(type),
                      size: 18,
                      color: orange,
                    ),
                    label: Text(type),
                    selected: selected,
                    showCheckmark: true,
                    checkmarkColor: orange,
                    selectedColor: amber,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected
                          ? orange
                          : const Color(0xFFE7DAC6),
                    ),
                    onSelected: _submitting
                        ? null
                        : (value) {
                            setState(() {
                              if (value) {
                                _selectedCareTypes.add(type);
                              } else {
                                _selectedCareTypes.remove(type);
                              }
                            });
                          },
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              const Text(
                'Describe the care provided',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: espresso,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                enabled: !_submitting,
                maxLines: 5,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText:
                      'Describe how you helped this animal...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the care provided.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Evidence Photograph',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: espresso,
                ),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _submitting ? null : _pickEvidencePhoto,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: amber,
                      width: 2,
                    ),
                  ),
                  child: _evidencePhoto == null
                      ? const Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_rounded,
                              size: 42,
                              color: orange,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Tap to add evidence',
                              style: TextStyle(
                                color: espresso,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Camera or Gallery',
                              style: TextStyle(
                                color: Color(0xFF8A7A66),
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius:
                              BorderRadius.circular(16),
                          child: Image.file(
                            _evidencePhoto!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),

              if (_evidencePhoto != null)
                TextButton.icon(
                  onPressed:
                      _submitting ? null : _pickEvidencePhoto,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Change photo'),
                  style: TextButton.styleFrom(
                    foregroundColor: orange,
                  ),
                ),

              const SizedBox(height: 30),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitCare,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.volunteer_activism),
                  label: Text(
                    _submitting
                        ? 'Submitting Care...'
                        : 'Submit Care Record',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        orange.withValues(alpha: 0.65),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
