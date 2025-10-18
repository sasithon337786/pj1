// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

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

// ===== THEME COLORS =====
class _AppColors {
  static const rose = Color(0xFFC98993); // ปุ่ม/แถบหลัก
  static const cream = Color(0xFFE6D2CD); // กล่อง/พื้น
  static const mocha = Color(0xFF564843); // ข้อความเข้ม
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
                          localSliderController.create?.call();
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

  Future<void> _showBlockedDialog(String status, String? _) async {
    final raw = status; // อาจเป็น '' ได้
    final st = (raw.isNotEmpty ? raw : 'unknown').trim().toLowerCase();
    final isSuspended = st == 'suspend' || st == 'suspended';
    final isDeleted = st == 'deleted';

    final title = 'ไม่สามารถเข้าสู่ระบบได้';
    final content = isSuspended
        ? 'คุณเข้าสู่ระบบไม่ได้เนื่องจากบัญชีถูกระงับการใช้งาน'
        : isDeleted
            ? 'คุณเข้าสู่ระบบไม่ได้เนื่องจากบัญชีของคุณถูกลบ'
            : 'คุณเข้าสู่ระบบไม่ได้ (สถานะ: $status)';

    final iconData =
        isDeleted ? Icons.delete_forever_rounded : Icons.block_rounded;

    if (!mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'blocked-dialog',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          child: Opacity(
            opacity: curved.value,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(ctx).size.width * 0.82,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  decoration: BoxDecoration(
                    color: _AppColors.cream,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon badge
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _AppColors.rose.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(iconData, size: 34, color: _AppColors.mocha),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kanit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.mocha,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          color: _AppColors.mocha.withOpacity(0.85),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ปุ่มปิด
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              backgroundColor: _AppColors.mocha,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text('ปิด',
                                style: GoogleFonts.kanit(fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleLogin() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      final data = await _authService.signInWithGoogle();

      // ผ่าน active แล้ว
      final role = data.role;

      // ✅ ดึง idToken สดใหม่จาก Firebase อีกครั้ง (กัน token หมดอายุ)
      final user = FirebaseAuth.instance.currentUser;
      final freshToken = await user?.getIdToken(true);

      if (freshToken == null) {
        throw Exception("ไม่สามารถดึง ID Token ได้");
      }

      // ✅ ใช้ token สดส่งไป backend สำหรับแจ้งเตือน
      await NotificationService.scheduleReminders(freshToken);

      _showSnack('Google sign-in สำเร็จ!', backgroundColor: Colors.green);

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainAdmin()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } on AuthBlockedException catch (e) {
      await _showBlockedDialog(e.status, e.message);
    } on PlatformException catch (e) {
      _showSnack('Platform Error: ${e.code} - ${e.message}');
    } on FirebaseAuthException catch (e) {
      _showSnack(_thaiMessageFromAuthCode(e.code, e.message));
    } catch (e) {
      _showSnack('Google login ล้มเหลว: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleEmailLogin() async {
    // validate + captcha
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || !isRobotChecked) {
      if (!isRobotChecked) {
        _showSnack("กรุณายืนยัน 'I'm not a robot'",
            backgroundColor: Colors.orange);
      }
      return;
    }
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      final data = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final role = data.role;

      // ✅ ดึง idToken สดจาก FirebaseAuth อีกครั้ง
      final user = FirebaseAuth.instance.currentUser;
      final freshToken = await user?.getIdToken(true);

      if (freshToken == null) {
        throw Exception("ไม่สามารถดึง ID Token ได้");
      }

      await NotificationService.scheduleReminders(freshToken);

      _showSnack('เข้าสู่ระบบสำเร็จ!', backgroundColor: Colors.green);

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainAdmin()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } on AuthBlockedException catch (e) {
      await _showBlockedDialog(e.status, e.message);
    } on FirebaseAuthException catch (e) {
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
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Enter a valid email address';
                        }
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
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
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
                          horizontal: 15,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isGoogleLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/icons/google.png',
                                    width: 24, height: 24),
                                const SizedBox(width: 10),
                                Text(
                                  'Login with Google',
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 15),

                    // Captcha
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              final ok = await _showCaptchaDialog();
                              if (ok == true) {
                                setState(() => isRobotChecked = true);
                              }
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
                                      const RegistrationScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF564843),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text('สมัครสมาชิก',
                                style: GoogleFonts.kanit(
                                    color: Colors.white, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await _handleEmailLogin();
                              } catch (e, st) {
                                debugPrint('Login press error: $e\n$st');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF564843),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
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
