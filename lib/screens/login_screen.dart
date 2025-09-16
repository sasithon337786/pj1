import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/screens/registration_screen.dart';
import 'package:pj1/widgets/custom_text_field.dart';
import 'package:pj1/widgets/captcha_dialog.dart';
import 'package:pj1/services/auth_service.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/mains.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool isRobotChecked = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  void _showSnackBar(String message, {Color backgroundColor = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate() || !isRobotChecked) {
      if (!isRobotChecked) {
        _showSnackBar("Please check 'I'm not a robot'.",
            backgroundColor: Colors.orange);
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = await _authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _navigateByRole(data.user.role);
    } catch (e) {
      _showSnackBar('Login failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      final data = await _authService.signInWithGoogle();
      _navigateByRole(data.user.role);
    } catch (e) {
      _showSnackBar('Google login failed: $e');
    } finally {
      setState(() => _isGoogleLoading = false);
    }
  }

  void _navigateByRole(String role) {
    _showSnackBar('Login successful!', backgroundColor: Colors.green);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => role == 'admin' ? const MainAdmin() : HomePage()),
    );
  }

  Future<void> _showCaptcha() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const CaptchaDialog(),
    );
    if (result == true) {
      setState(() => isRobotChecked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 160, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Login", style: GoogleFonts.kanit(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),

              CustomTextField(
                controller: _emailController,
                icon: Image.asset('assets/icons/profile.png', width: 35, height: 35),
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter valid email'
                    : null,
              ),

              const SizedBox(height: 15),

              CustomTextField(
                controller: _passwordController,
                icon: Image.asset('assets/icons/lock.png', width: 35, height: 35),
                hintText: 'Password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) =>
                    value == null || value.length < 6 ? 'Password too short' : null,
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
                child: _isGoogleLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login with Google"),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  IconButton(
                    icon: Icon(isRobotChecked ? Icons.check_circle : Icons.check_circle_outline,
                        color: isRobotChecked ? Colors.green : Colors.grey),
                    onPressed: _showCaptcha,
                  ),
                  Text("I'M NOT A ROBOT", style: GoogleFonts.kanit(fontSize: 16)),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegistrationScreen())),
                      child: const Text("สมัครสมาชิก"),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("เข้าสู่ระบบ"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
