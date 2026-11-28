import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const _accent = Color(0xFFBF5700);
  static const _ink = Color(0xFF49270F);
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _hidden = [true, true, true];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await AuthService().changePassword(
      currentPassword: _current.text,
      newPassword: _next.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) {
      _current.clear();
      _next.clear();
      _confirm.clear();
      Navigator.of(context).pop(true);
    }
  }

  Widget _field(
    int index,
    String label,
    TextEditingController controller,
    String? Function(String?) validator,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !_busy,
        obscureText: _hidden[index],
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: index == 2
            ? TextInputAction.done
            : TextInputAction.next,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.lock_outline, color: _accent),
          suffixIcon: IconButton(
            tooltip: _hidden[index] ? 'Show password' : 'Hide password',
            onPressed: _busy
                ? null
                : () => setState(() => _hidden[index] = !_hidden[index]),
            icon: Icon(
              _hidden[index] ? Icons.visibility_off : Icons.visibility,
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBE8BC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFBE8BC),
          foregroundColor: _ink,
          title: const Text('Change Password'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF8ED),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _accent),
                  ),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.lock_reset_rounded,
                          size: 52,
                          color: _accent,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Keep your PAWLY account secure.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _ink, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        _field(
                          0,
                          'Current password',
                          _current,
                          (v) => v == null || v.isEmpty
                              ? 'Enter your current password.'
                              : null,
                        ),
                        _field(1, 'New password', _next, (v) {
                          if (v == null || v.length < 8) {
                            return 'Use at least 8 characters.';
                          }
                          if (v == _current.text) {
                            return 'Choose a different password.';
                          }
                          return null;
                        }),
                        _field(
                          2,
                          'Confirm new password',
                          _confirm,
                          (v) => v != _next.text || v == null || v.isEmpty
                              ? 'Passwords do not match.'
                              : null,
                        ),
                        if (_error != null) ...[
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        ElevatedButton(
                          onPressed: _busy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Update Password'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: _ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
