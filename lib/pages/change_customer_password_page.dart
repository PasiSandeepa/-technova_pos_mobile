import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ChangeCustomerPasswordPage extends StatefulWidget {
  final HttpAuthRepository repository;
  final CustomerSessionStore sessionStore;
  final WidgetBuilder loginPageBuilder;

  const ChangeCustomerPasswordPage({
    super.key,
    required this.repository,
    required this.sessionStore,
    required this.loginPageBuilder,
  });

  @override
  State<ChangeCustomerPasswordPage> createState() =>
      _ChangeCustomerPasswordPageState();
}

class _ChangeCustomerPasswordPageState
    extends State<ChangeCustomerPasswordPage> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newPassword.text.length < 8) {
      _showMessage('New password must contain at least 8 characters.');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      _showMessage('The new passwords do not match.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.repository.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      await widget.sessionStore.clear();
      widget.repository.accessToken = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated. Please sign in again.'),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: widget.loginPageBuilder),
        (route) => false,
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update your password')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              const Text(
                'Create a new password to continue to your account.',
                style: TextStyle(color: Color(0xFF68736C)),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _currentPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _newPassword,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
