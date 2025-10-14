import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http; // (ใช้ถ้าต้องเรียก backend เพิ่ม)
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/registration_screen.dart';
import 'package:pj1/services/notification_service.dart';
import 'package:pj1/services/auth_service.dart';
import 'package:slider_captcha/slider_captcha.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SliderController _sliderController = SliderController();
  final AuthService _authService = AuthService();

  bool isRobotChecked = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  Future<bool?> _showCaptchaDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String localCaptchaErrorText = "";
        SliderController localSliderController = SliderController();

        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async {
                if (localCaptchaErrorText.isNotEmpty) return false;
                return true;
              },
              child: AlertDialog(
                backgroundColor: const Color(0xFFE6D2CD),
                title: Text(
                  "ยืนยันความเป็นมนุษย์",
                  style: GoogleFonts.kanit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF564843),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderCaptcha(
                      controller: localSliderController,
                      image: Image.asset(
                        'assets/images/catty.jpg',
                        fit: BoxFit.fitWidth,
                      ),
                      colorBar: const Color(0xFFC98993),
                      colorCaptChar: const Color(0xFFE6D2CD),
                      onConfirm: (ok) async {
                        if (ok) {
                          setState(() => localCaptchaErrorText = "");
                          Navigator.pop(context, true);
                        } else {
                          setState(() => localCaptchaErrorText =
                              "พบข้อผิดพลาด กรุณาลองใหม่อีกครั้ง");
                          await Future.delayed(const Duration(seconds: 2));
                          localSliderController.create.call();
                          setState(() => localCaptchaErrorText = "");
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    if (localCaptchaErrorText.isNotEmpty)
                      Text(
                        localCaptchaErrorText,
                        style:
                            GoogleFonts.kanit(color: Colors.red, fontSize: 16),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {Color backgroundColor = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String _thaiMessageFromAuthCode(String code, String? fallback) {
    switch (code) {
      case 'invalid-email':
        return 'อีเมลไม่ถูกต้อง';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-credential':
        return 'ข้อมูลรับรองไม่ถูกต้อง/หมดอายุ (ตรวจโปรเจกต์/เวลาเครื่อง/App Check)';
      case 'user-disabled':
        return 'บัญชีนี้ถูกปิดการใช้งาน';
      case 'too-many-requests':
        return 'พยายามมากเกินไป โปรดลองใหม่ภายหลัง';
      case 'network-request-failed':
        return 'เครือข่ายมีปัญหา ตรวจสอบการเชื่อมต่อ';
      default:
        return fallback?.isNotEmpty == true
            ? fallback!
            : 'ล็อกอินไม่ได้: $code';
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final data = await _authService.signInWithGoogle();
      final role = data.role;
      final idToken = data.token;
      // debugPrint("🔔 เรียกข้อมูลกิจกรรมจาก backend...");
      // await NotificationService.scheduleReminders(idToken);
      // debugPrint("✅ เรียกการตั้งค่าแจ้งเตือนเสร็จสิ้น");
      _showSnack('Google sign-in สำเร็จ!', backgroundColor: Colors.green);
      if (role == 'admin') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainAdmin()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => HomePage()));
      }
    } on PlatformException catch (e) {
      // ✅ แสดง error แบบละเอียด
      print('PlatformException code: ${e.code}');
      print('PlatformException message: ${e.message}');
      print('PlatformException details: ${e.details}');
      _showSnack('Platform Error: ${e.code} - ${e.message}');
    } on FirebaseAuthException catch (e) {
      _showSnack(_thaiMessageFromAuthCode(e.code, e.message));
    } catch (e) {
      print('Unknown error: $e');
      _showSnack('Google login ล้มเหลว: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleEmailLogin() async {
    // validate + captcha
    if (!_formKey.currentState!.validate() || !isRobotChecked) {
      if (!isRobotChecked) {
        _showSnack("กรุณายืนยัน 'I'm not a robot'",
            backgroundColor: Colors.orange);
      }
      return;
    }
    if (_isLoading) return;

    final email = _emailController.text.trim(); // ✅ กันช่องว่างหัวท้าย
    final password =
        _passwordController.text; // ไม่ trim เพื่อเคารพรหัสผ่านผู้ใช้

    setState(() => _isLoading = true);
    try {
      final data = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final role = data.role;
      final idToken = data.token;
      // debugPrint("🔔 เรียกข้อมูลกิจกรรมจาก backend...");
      // await NotificationService.scheduleReminders(idToken);
      // debugPrint("✅ เรียกการตั้งค่าแจ้งเตือนเสร็จสิ้น");
      _showSnack('เข้าสู่ระบบสำเร็จ!', backgroundColor: Colors.green);
      if (role == 'admin') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainAdmin()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => HomePage()));
      }
    } on FirebaseAuthException catch (e) {
      // ✅ โชว์สาเหตุจริง เช่น wrong-password, user-not-found, invalid-credential
      _showSnack(_thaiMessageFromAuthCode(e.code, e.message));
    } catch (e) {
      _showSnack('เข้าสู่ระบบล้มเหลว: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 160,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6D2CD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/icons/enter.png',
                            width: 25, height: 25),
                        const SizedBox(width: 5),
                        Text(
                          'Login',
                          style: GoogleFonts.kanit(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      iconWidget: Image.asset('assets/icons/profile.png',
                          width: 35, height: 35),
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) return 'Please enter your email';
                        if (!v.contains('@') || !v.contains('.'))
                          return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Password
                    _buildTextField(
                      controller: _passwordController,
                      iconWidget: Image.asset('assets/icons/lock.png',
                          width: 35, height: 35),
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter your password';
                        if (value.length < 6)
                          return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Google Sign-in
                    ElevatedButton(
                      onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC98993),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isGoogleLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/icons/google.png',
                                    width: 24, height: 24),
                                const SizedBox(width: 10),
                                Text('Login with Google',
                                    style: GoogleFonts.kanit(
                                        color: Colors.white, fontSize: 16)),
                              ],
                            ),
                    ),
                    const SizedBox(height: 15),

                    // Captcha (I'm not a robot)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              final ok = await _showCaptchaDialog();
                              if (ok == true)
                                setState(() => isRobotChecked = true);
                            },
                            icon: Icon(
                              isRobotChecked
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color:
                                  isRobotChecked ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("I'M NOT A ROBOT",
                              style: GoogleFonts.kanit(fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const RegistrationScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF564843),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text('สมัครสมาชิก',
                                style: GoogleFonts.kanit(
                                    color: Colors.white, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleEmailLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF564843),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text('เข้าสู่ระบบ',
                                    style: GoogleFonts.kanit(
                                        color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === UI helper ===
  Widget _buildTextField({
    required TextEditingController controller,
    required Widget iconWidget,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.kanit(color: Colors.white, fontSize: 16),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon:
            Padding(padding: const EdgeInsets.all(12.0), child: iconWidget),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: GoogleFonts.kanit(color: Colors.white70, fontSize: 16),
        filled: true,
        fillColor: const Color(0xFFC98993),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: GoogleFonts.kanit(color: Colors.white),
      ),
    );
  }
}
