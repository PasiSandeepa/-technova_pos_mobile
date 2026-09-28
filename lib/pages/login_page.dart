import 'package:flutter/material.dart';
import 'package:technova_pos_mobile/pages/fogot_page.dart';
import 'app_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool rememberMe = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
                  // ─────────────────────────────
                  // TECHNOVA LOGO
                  // ─────────────────────────────
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

            

                  // ─────────────────────────────
                  // SIGN IN TITLE
                  // ─────────────────────────────
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202124),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Access the Dreampos panel using your email and passcode.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF888888)),
                  ),

                  const SizedBox(height: 25),

                  // ─────────────────────────────
                  // EMAIL LABEL
                  // ─────────────────────────────
                  const Row(
                    children: [
                      Text(
                        'Email',
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

                  // EMAIL FIELD
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '',
                      suffixIcon: const Icon(
                        Icons.alternate_email,
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

                  // ─────────────────────────────
                  // PASSWORD LABEL
                  // ─────────────────────────────
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
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 17,
                          color: const Color(0xFF777777),
                        ),
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

               // ─────────────────────────────
      // REMEMBER + FORGOT
      // ─────────────────────────────
      Row(
        children: [
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

          GestureDetector(
            onTap: () {
           
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForgotPasswordPage(),
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

                  // ─────────────────────────────
                  // SIGN IN BUTTON
                  // ─────────────────────────────
SizedBox(
  width: double.infinity,
  height: 38,
  child: ElevatedButton(
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AppLayout(),
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0D9488),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
    ),
    child: const Text(
      'Sign In',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),

                  const SizedBox(height: 17),

                  // ─────────────────────────────
                  // REGISTER
                  // ─────────────────────────────
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF888888),
                        ),
                        children: [
                          const TextSpan(text: 'New on our platform? '),
                          TextSpan(
                            text: 'Create an account',
                            style: const TextStyle(
                              color: Color(0xFF0D9488),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ─────────────────────────────
                  // OR
                  // ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFEEEEEE),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFEEEEEE),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // ─────────────────────────────
                  // GOOGLE BUTTON
                  // ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () {
                        // Google login
                      },
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

                  const SizedBox(height: 85),

                  // ─────────────────────────────
                  // COPYRIGHT
                  // ─────────────────────────────
                 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
