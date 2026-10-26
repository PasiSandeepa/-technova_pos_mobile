import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:technova_pos_mobile/services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  final bool isStaff;
  final String initialEmail;

  const ForgotPasswordPage({
    super.key,
    this.isStaff = false,
    this.initialEmail = '',
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final HttpAuthRepository _authRepository = HttpAuthRepository();

  int _step = 0;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _challengeToken;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _authRepository.close();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showMessage('Enter a valid registered email address.');
      return;
    }

    await _runRequest(() async {
      _challengeToken = widget.isStaff
          ? await _authRepository.requestStaffPasswordReset(email: email)
          : await _authRepository.requestCustomerPasswordReset(email: email);
      _step = 1;
      _showMessage('A six-digit reset code was sent to your email.');
    });
  }

  Future<void> _verifyCode() async {
    final otp = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showMessage('Enter the six-digit code from your email.');
      return;
    }

    await _runRequest(() async {
      _resetToken = widget.isStaff
          ? await _authRepository.verifyStaffPasswordResetOtp(
              challengeToken: _challengeToken!,
              otp: otp,
            )
          : await _authRepository.verifyCustomerPasswordResetOtp(
              challengeToken: _challengeToken!,
              otp: otp,
            );
      _step = 2;
    });
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final validPassword = widget.isStaff
        ? password.isNotEmpty
        : password.length >= 12 &&
              password.length <= 128 &&
              RegExp(r'[A-Z]').hasMatch(password) &&
              RegExp(r'[a-z]').hasMatch(password) &&
              RegExp(r'\d').hasMatch(password) &&
              RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    if (!validPassword) {
      _showMessage(
        widget.isStaff
            ? 'Enter a new password.'
            : 'Use 12–128 characters with uppercase, lowercase, a number, and a symbol.',
      );
      return;
    }

    await _runRequest(() async {
      if (widget.isStaff) {
        await _authRepository.resetStaffPassword(
          resetToken: _resetToken!,
          password: password,
        );
      } else {
        await _authRepository.resetCustomerPassword(
          resetToken: _resetToken!,
          password: password,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isStaff
                ? 'Password reset. Sign in with your work email and new password.'
                : 'Password reset. Sign in with your phone and new password.',
          ),
        ),
      );
      Navigator.pop(context);
    });
  }

  Future<void> _runRequest(Future<void> Function() action) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await action();
      if (mounted) setState(() {});
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goBackOneStep() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step--);
  }

  String get _title => switch (_step) {
    0 => 'Forgot password?',
    1 => 'Verify your email',
    _ => 'Create a new password',
  };

  String get _description => switch (_step) {
    0 => widget.isStaff
        ? 'Enter the email registered to your staff account. We’ll send a reset code.'
        : 'Enter the email registered to your customer account. We’ll send a reset code.',
    1 => 'Enter the six-digit code sent to ${_emailController.text.trim()}. It expires in 10 minutes.',
    _ => widget.isStaff
        ? 'Choose a new password for your staff account.'
        : 'Choose a password with 12–128 characters, including uppercase, lowercase, a number, and a symbol.',
  };

  String get _buttonLabel => switch (_step) {
    0 => 'Send reset code',
    1 => 'Verify code',
    _ => 'Reset password',
  };

  Future<void> _submit() => switch (_step) {
    0 => _requestCode(),
    1 => _verifyCode(),
    _ => _resetPassword(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/technova-logo-transparent.png',
                      width: 280,
                      height: 199,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 35),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _goBackOneStep,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 17, color: Color(0xFF777777)),
                        SizedBox(width: 6),
                        Text(
                          'Back',
                          style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _description,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 25),
                  if (_step == 0) ...[
                    _fieldLabel('Registered email'),
                    const SizedBox(height: 7),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isSubmitting,
                      decoration: _inputDecoration(
                        hint: widget.isStaff
                            ? 'employee@example.com'
                            : 'customer@example.com',
                        icon: Icons.mail_outline,
                      ),
                    ),
                  ] else if (_step == 1) ...[
                    _fieldLabel('Six-digit reset code'),
                    const SizedBox(height: 7),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      enabled: !_isSubmitting,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: _inputDecoration(
                        hint: '123456',
                        icon: Icons.lock_outline,
                      ),
                    ),
                  ] else ...[
                    _fieldLabel('New password'),
                    const SizedBox(height: 7),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isSubmitting,
                      decoration: _inputDecoration(
                        hint: 'Enter a strong password',
                        icon: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 17,
                            color: const Color(0xFF777777),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _buttonLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  if (_step == 1) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _isSubmitting ? null : _requestCode,
                        child: const Text(
                          'Resend code',
                          style: TextStyle(color: Color(0xFF0D9488)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 55),
                  const Center(
                    child: Text(
                      '2026 © TechNova. All Rights Reserved',
                      style: TextStyle(fontSize: 8, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF444444),
        ),
      ),
      const Text(' *', style: TextStyle(fontSize: 12, color: Colors.red)),
    ],
  );

  InputDecoration _inputDecoration({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        suffixIcon: Icon(icon, size: 17, color: const Color(0xFF777777)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFF0D9488)),
        ),
      );
}
