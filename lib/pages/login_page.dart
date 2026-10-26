import 'package:flutter/material.dart';
import 'package:technova_pos_mobile/pages/fogot_page.dart';
import 'package:technova_pos_mobile/services/auth_service.dart';
import 'package:technova_pos_mobile/services/google_identity_service.dart';
import 'package:technova_pos_mobile/services/staff_api_service.dart';
import 'app_layout.dart';
import 'change_customer_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerPasswordController =
      TextEditingController();
  final TextEditingController _staffEmailController = TextEditingController();
  final TextEditingController _staffPasswordController =
      TextEditingController();

  final HttpAuthRepository _authRepository = HttpAuthRepository();
  final CustomerSessionStore _sessionStore = CustomerSessionStore();
  final StaffApiService _staffApi = StaffApiService();
  final GoogleIdentityService _googleIdentityService = GoogleIdentityService();

  bool isStaffLogin = false;
  bool rememberMe = false;
  bool obscurePassword = true;
  bool _isSubmitting = false;

  TextEditingController get _identityController =>
      isStaffLogin ? _staffEmailController : _customerPhoneController;

  TextEditingController get _passwordController =>
      isStaffLogin ? _staffPasswordController : _customerPasswordController;

  @override
  void dispose() {
    _customerPhoneController.dispose();
    _customerPasswordController.dispose();
    _staffEmailController.dispose();
    _staffPasswordController.dispose();
    _staffApi.close();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identity = _identityController.text.trim();
    final password = _passwordController.text;

    if (identity.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your sign-in details.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (isStaffLogin) {
        final login = await _staffApi.login(
          email: identity,
          password: password,
        );
        final user = await _staffApi.getMe();
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AppLayout(
              initialRoute: user.roles.contains('SUPPLIER')
                  ? 'Supplier'
                  : 'Dashboard',
              staffAccessToken: login.accessToken,
              staffUser: user,
            ),
          ),
        );
        return;
      }

      final response = await _authRepository.login(
        phone: identity,
        password: password,
      );
      if (rememberMe) {
        await _sessionStore.save(response);
      } else {
        await _sessionStore.clear();
      }

      if (!mounted) return;

      if (response.user.mustChangePassword) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeCustomerPasswordPage(
              repository: _authRepository,
              sessionStore: _sessionStore,
              loginPageBuilder: (_) => const LoginPage(),
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful.')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppLayout(
            initialRoute: 'Customer Dashboard',
            customerMode: true,
            customerUser: response.user,
            customerAccessToken: response.tokens.accessToken,
            customerRefreshToken: response.tokens.refreshToken,
            persistCustomerSession: rememberMe,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    // Google authentication is available only for customer accounts.
    if (isStaffLogin || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final idToken = await _googleIdentityService.getIdToken();

      final response = await _authRepository.loginWithGoogleIdToken(
        idToken: idToken,
      );
      if (rememberMe) {
        await _sessionStore.save(response);
      } else {
        await _sessionStore.clear();
      }
      if (!mounted) return;

      if (response.user.mustChangePassword) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeCustomerPasswordPage(
              repository: _authRepository,
              sessionStore: _sessionStore,
              loginPageBuilder: (_) => const LoginPage(),
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AppLayout(
            initialRoute: 'Customer Dashboard',
            customerMode: true,
            customerUser: response.user,
            customerAccessToken: response.tokens.accessToken,
            customerRefreshToken: response.tokens.refreshToken,
            persistCustomerSession: rememberMe,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  // TECHNOVA LOGO
                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/technova-logo-transparent.png',
                          width: 280,
                          height: 199,
                        ),
                      ],
                    ),
                  ),

                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  // SIGN IN TITLE
                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Customer')),
                      ButtonSegment(value: true, label: Text('Staff')),
                    ],
                    selected: {isStaffLogin},
                    onSelectionChanged: _isSubmitting
                        ? null
                        : (selection) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() => isStaffLogin = selection.first);
                          },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202124),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    isStaffLogin
                        ? 'Sign in with your work email.'
                        : 'Sign in to your customer account with your phone number.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF888888)),
                  ),

                  const SizedBox(height: 25),

                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  // PHONE LABEL
                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Row(
                    children: [
                      Text(
                        isStaffLogin ? 'Work email' : 'Phone number',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF444444),
                        ),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  // PHONE FIELD
                  TextField(
                    key: ValueKey(
                      isStaffLogin ? 'staff-identity-field' : 'customer-phone-field',
                    ),
                    controller: _identityController,
                    keyboardType: isStaffLogin
                        ? TextInputType.emailAddress
                        : TextInputType.phone,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: isStaffLogin
                          ? 'name@company.com'
                          : '+94771234567',
                      suffixIcon: Icon(
                        isStaffLogin
                            ? Icons.email_outlined
                            : Icons.phone_outlined,
                        size: 15,
                        color: Color(0xFF777777),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
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
                    ),
                  ),

                  const SizedBox(height: 18),

                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  // PASSWORD LABEL
                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  const Row(
                    children: [
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF444444),
                        ),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  // PASSWORD FIELD
                  TextField(
                    key: ValueKey(
                      isStaffLogin ? 'staff-password-field' : 'customer-password-field',
                    ),
                    controller: _passwordController,
                    obscureText: obscurePassword,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 17,
                          color: const Color(0xFF777777),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
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
                    ),
                  ),

                  const SizedBox(height: 11),

                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  // REMEMBER + FORGOT
                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Row(
                    children: [
                      if (!isStaffLogin) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: rememberMe,
                            activeColor: const Color(0xFF0D9488),
                            onChanged: (value) {
                              setState(() {
                                rememberMe = value ?? false;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 5),

                        const Text(
                          'Remember Me',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF777777),
                          ),
                        ),
                        const Spacer(),
                      ],
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordPage(
                                  isStaff: isStaffLogin,
                                  initialEmail: isStaffLogin
                                      ? _staffEmailController.text.trim()
                                      : '',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF0D9488),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  // SIGN IN BUTTON
                  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleLogin,
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
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 17),

               

                 
                  if (!isStaffLogin) ...[
                    // GOOGLE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _handleGoogleLogin,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFEAEAEA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF4285F4),
                              Color(0xFF34A853),
                              Color(0xFFFBBC05),
                              Color(0xFFEA4335),
                              Color(0xFF4285F4),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                
                  // COPYRIGHT
                
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
              
