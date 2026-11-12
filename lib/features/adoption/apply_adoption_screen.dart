import 'package:flutter/material.dart';

import 'adoption_service.dart';

class ApplyAdoptionScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const ApplyAdoptionScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<ApplyAdoptionScreen> createState() => _ApplyAdoptionScreenState();
}

class _ApplyAdoptionScreenState extends State<ApplyAdoptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String _applicationType = 'Adoption'; // 'Adoption' or 'Foster'
  String _housingType = 'Own House (Fenced Garden)';
  bool _hasOtherPets = false;
  bool _isSubmitting = false;

  static const Color bgColor = Color(0xFFFCECD7);
  static const Color primaryOrange = Color(0xFFD46211);
  static const Color textDark = Color(0xFF26160C);

  final AdoptionService _adoptionService = AdoptionService();

  Future<void> _handleSubmission() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _adoptionService.submitApplication(
        petId: widget.petId,
        petName: widget.petName,
        applicationType: _applicationType,
        applicantName: _nameController.text.trim(),
        applicantPhone: _phoneController.text.trim(),
        housingType: _housingType,
        hasOtherPets: _hasOtherPets,
        experienceDetails: _experienceController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.petName} adoption request submitted successfully!',
            ),
            backgroundColor: primaryOrange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.brown.shade800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Apply for ${widget.petName}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: textDark,
            fontSize: 18,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Application Type Selection
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Permanent Adoption')),
                      selected: _applicationType == 'Adoption',
                      selectedColor: primaryOrange,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _applicationType == 'Adoption'
                            ? Colors.white
                            : textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: _applicationType == 'Adoption'
                            ? primaryOrange
                            : const Color(0xFFE8D3BF),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _applicationType = 'Adoption');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Temporary Foster')),
                      selected: _applicationType == 'Foster',
                      selectedColor: primaryOrange,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _applicationType == 'Foster'
                            ? Colors.white
                            : textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: _applicationType == 'Foster'
                            ? primaryOrange
                            : const Color(0xFFE8D3BF),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _applicationType = 'Foster');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Applicant Full Name'),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.brown.shade300,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Contact Phone Number'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '07x xxx xxxx',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.brown.shade300,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter contact number'
                    : null,
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Housing Environment'),
              DropdownButtonFormField<String>(
                value: _housingType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items:
                    [
                          'Own House (Fenced Garden)',
                          'Own House (Open Area)',
                          'Apartment / Flat',
                          'Rented House (Pets Allowed)',
                        ]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _housingType = val);
                },
              ),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Do you currently own other pets?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  value: _hasOtherPets,
                  activeColor: primaryOrange,
                  onChanged: (val) => setState(() => _hasOtherPets = val),
                ),
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Previous Experience & Care Plans'),
              TextFormField(
                controller: _experienceController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe your daily schedule, past pet experience, and care arrangements...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.brown.shade300,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit $_applicationType Request',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
