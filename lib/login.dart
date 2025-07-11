import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/Services/ApiService.dart'; // Make sure ApiService is correctly implemented
import 'package:pj1/add.dart'; // This seems to be MainHomeScreen, rename for clarity if needed
import 'package:pj1/registration_screen.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/constant/api_endpoint.dart';
import 'package:slider_captcha/slider_captcha.dart';
import 'package:pj1/constant/api_endpoint.dart'; // Make sure ApiEndpoints.baseUrl is defined

// Assuming you have a separate screen for admin

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
  String _captchaErrorText = "";

  bool isRobotChecked = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  final api = ApiService();
  Future<bool?> _showCaptchaDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // ป้องกันกดนอก dialog ปิด
      builder: (BuildContext context) {
        String localCaptchaErrorText = "";
        SliderController localSliderController = SliderController();

        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              // ป้องกันกดปุ่ม back ปิด dialog
              onWillPop: () async {
                // ถ้ามี error หรือยังไม่ผ่าน captcha ให้บล็อกการปิด
                if (localCaptchaErrorText.isNotEmpty) {
                  return false;
                }
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
                      onConfirm: (value) async {
                        print('Captcha result: $value');

                        if (value) {
                          setState(() {
                            localCaptchaErrorText = "";
                          });
                          Navigator.pop(context, true); // ส่ง true กลับไป
                        } else {
                          setState(() {
                            localCaptchaErrorText =
                                "พบข้อผิดพลาด กรุณาลองใหม่อีกครั้ง";
                          });
                          await Future.delayed(const Duration(seconds: 3));
                          localSliderController.create.call(); // reset captcha
                          setState(() {
                            localCaptchaErrorText = "";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    if (localCaptchaErrorText.isNotEmpty)
                      Text(
                        localCaptchaErrorText,
                        style: GoogleFonts.kanit(
                          color: Colors.red,
                          fontSize: 16,
                        ),
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

  final ApiService api =
      ApiService(); // Assuming ApiService is used elsewhere, kept it here.

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return; // Prevent multiple taps

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in with Google');
      }

      final idToken = await user.getIdToken();

      // Send ID Token to your backend for role verification and custom JWT
      final response = await http.post(
        Uri.parse(ApiEndpoints.baseUrl + '/api/auth/loginwithgoogle'),
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/loginwithgoogle'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['user']['role'];
        final token = data['token']; // Backend's custom JWT, if any

        // You might want to save 'token' (your backend's JWT) securely, e.g., using flutter_secure_storage.
        // api.saveToken(token); // Example if ApiService handles token storage
        print('Google Sign-In User Role: $role');
        _showSnackBar('Google sign-in successful!',
            backgroundColor: Colors.green);

        // Navigate based on role
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const MainAdmin()), // Navigate to Admin screen
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MainHomeScreen()), // Navigate to regular user screen
          );
        }
      } else {
        final error =
            jsonDecode(response.body)['message'] ?? 'Server rejected token';
        throw Exception(error);
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Firebase error: ${e.message}');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    print(message);
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate() || !isRobotChecked) {
      if (!isRobotChecked) {
        _showSnackBar("Please check 'I'm not a robot'.",
            backgroundColor: Colors.orange);
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Log in via Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      // ✅ 2. ไม่ตรวจ emailVerified อีกต่อไป

      // 3. Get Firebase ID Token
      final idToken = await user!.getIdToken(true);

      // 4. ส่ง token ไป backend
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/loginwithemail'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      // 5. ตรวจสอบ response จาก backend
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];
        final token = data['token'];

        _showSnackBar('Login successful!', backgroundColor: Colors.green);

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainAdmin()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainHomeScreen()),
          );
        }
      } else {
        final error =
            jsonDecode(response.body)['message'] ?? 'Unknown error from server';
        _showSnackBar('Login failed: $error');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = 'Login failed. Please try again. (${e.code})';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('An unexpected error occurred: ${e.toString()}');
      print('Unexpected error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar(
          'Please enter a valid email address first to reset password.',
          backgroundColor: Colors.orange);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar('Password reset email sent! Check your inbox.',
          backgroundColor: Colors.green);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage =
              'Failed to send reset email. Please try again. (${e.code})';
      }
      _showSnackBar(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          // Logo positioned at the top
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

          // Login form container
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
                // Added Form widget for validation
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Login title + icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/enter.png',
                          width: 25,
                          height: 25,
                        ),
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

                    // Email input
                    _buildTextField(
                      controller: _emailController,
                      iconWidget: Image.asset(
                        'assets/icons/profile.png',
                        width: 35,
                        height: 35,
                      ),
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Password input
                    _buildTextField(
                      controller: _passwordController,
                      iconWidget: Image.asset(
                        'assets/icons/lock.png',
                        width: 35,
                        height: 35,
                      ),
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
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

                    // Forgot password
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: TextButton(
                    //     onPressed: _resetPassword,
                    //     child: Text(
                    //       'Forgot Password?',
                    //       style: GoogleFonts.kanit(
                    //         color: Colors.white,
                    //         fontSize: 14,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 5),

                    // Login with Google button
                    ElevatedButton(
                      onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC98993),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isGoogleLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/google.png',
                                  width: 24,
                                  height: 24,
                                ),
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

                    // I'm not a robot checkbox
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              final result = await _showCaptchaDialog();
                              if (result == true) {
                                setState(() {
                                  isRobotChecked = true;
                                });
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
                          Text(
                            "I'M NOT A ROBOT",
                            style: GoogleFonts.kanit(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    // "I'm not a robot" checkbox
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0), // Reduced vertical padding
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isRobotChecked,
                            onChanged: (value) {
                              setState(() {
                                isRobotChecked = value!;
                              });
                            },
                            activeColor: const Color(0xFFD08C94),
                            checkColor: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "I'm not a robot",
                            style: GoogleFonts.kanit(fontSize: 16),
                          ),
                          const Spacer(),
                          Image.asset(
                            'assets/icons/life.png', // Assuming this is your reCAPTCHA-like icon
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Register and Login buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          // Use Expanded to make buttons fill available space
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12), // Adjusted padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'สมัครสมาชิก',
                              style: GoogleFonts.kanit(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15), // Space between buttons
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _signInWithEmailAndPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF564843),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12), // Adjusted padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    'เข้าสู่ระบบ',
                                    style: GoogleFonts.kanit(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
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

  // Helper function to build TextField with consistent styling
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
      // Changed to TextFormField for built-in validation
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.kanit(
        color: Colors.white,
        fontSize: 16,
      ),
      keyboardType: keyboardType,
      validator: validator, // Added validator
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: iconWidget,
        ),
        suffixIcon:
            suffixIcon, // Added suffixIcon for password visibility toggle
        hintText: hintText,
        hintStyle: GoogleFonts.kanit(
          color: Colors.white70,
          fontSize: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFC98993),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: GoogleFonts.kanit(
            color: Colors.white), // Style for validation errors
      ),
    );
  }
}
