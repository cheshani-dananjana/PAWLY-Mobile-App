
import 'package:flutter/material.dart';

import 'report_service.dart';

class ReportPostScreen extends StatefulWidget {
  const ReportPostScreen({
    super.key,
    required this.postId,
    required this.animalName,
  });

  final String postId;
  final String animalName;

  @override
  State<ReportPostScreen> createState() =>
      _ReportPostScreenState();
}

class _ReportPostScreenState extends State<ReportPostScreen> {
  static const Color cream = Color(0xFFFDF8ED);
  static const Color orange = Color(0xFFBF5700);
  static const Color dark = Color(0xFF251605);

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedReason;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitReport() async {
    if (_submitting) return;

    final reason = _selectedReason;

    if (reason == null) {
      _showError('Please select a reporting reason.');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
    });

    try {
      await ReportService.submitReport(
        postId: widget.postId,
        reason: reason,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: cream,
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: orange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text('Report Submitted'),
              ),
            ],
          ),
          content: const Text(
            'Thank you for reporting this post. '
            'Your report has been sent for '
            'administrator review.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text(
                'Done',
                style: TextStyle(color: orange),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showError('Unable to submit report: $e');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text(
          'Report a Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: cream,
        foregroundColor: dark,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Information header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0DC),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reporting ${widget.animalName}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Help keep PAWLY safe for '
                      'animals and the community.',
                      style: TextStyle(
                        color: Color(0xFF8A7A66),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Why are you reporting this post?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: dark,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Select the reason that best '
                'describes the issue.',
                style: TextStyle(
                  color: Color(0xFF8A7A66),
                ),
              ),

              const SizedBox(height: 16),

              // Reporting reasons
              ...ReportService.reasons.map((reason) {
                final selected =
                    _selectedReason == reason;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: InkWell(
                    onTap: _submitting
                        ? null
                        : () {
                            setState(() {
                              _selectedReason = reason;
                            });
                          },
                    borderRadius:
                        BorderRadius.circular(14),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFE9CD)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? orange
                              : const Color(0xFFE7DAC6),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 15,
                                color: dark,
                              ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: selected
                                ? orange
                                : const Color(0xFFB8A995),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              const Text(
                'Additional Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: dark,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _selectedReason == 'Other'
                    ? 'Please explain the problem.'
                    : 'Optional: Tell us more about the issue.',
                style: const TextStyle(
                  color: Color(0xFF8A7A66),
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
                      'Describe what is wrong with this post...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (_selectedReason == 'Other' &&
                      (value == null ||
                          value.trim().isEmpty)) {
                    return 'Please describe the problem.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: orange,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reports are sent for administrator '
                      'review. Submitting a report does not '
                      'automatically remove the post.',
                      style: TextStyle(
                        color: Color(0xFF8A7A66),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submitting
                      ? null
                      : _submitReport,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.flag_rounded,
                        ),
                  label: Text(
                    _submitting
                        ? 'Submitting Report...'
                        : 'Submit Report',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        orange.withValues(alpha: 0.65),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
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
