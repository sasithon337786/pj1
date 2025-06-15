import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pj1/Services/ApiService.dart';
import 'package:pj1/registration_screen.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/constant/api_endpoint.dart';

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

  bool isRobotChecked = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  final api = ApiService();

  Future<void> _signInWithGoogle() async {
  setState(() {
    _isGoogleLoading = true;
  });

  try {
    // เริ่ม Google Sign-In
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // ผู้ใช้กดยกเลิก
      return;
    }

    // รับ token จาก Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // สร้าง credential สำหรับ Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // ล็อกอินเข้า Firebase
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Failed to sign in with Google');
    }

    // 🔐 รับ Firebase ID Token เพื่อส่งไป Backend
    final idToken = await user.getIdToken();

    // TODO: ส่ง idToken ไป Backend (ตัวอย่างด้านล่าง)
    final response = await http.post(
      Uri.parse(ApiEndpoints.baseUrl+'/api/auth/verify-token'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      throw Exception('Server rejected token');
    }
  } on FirebaseAuthException catch (e) {
    _showError('Firebase error: ${e.message}');
  } catch (e) {
    _showError('Error: ${e.toString()}');
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
}

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please verify your email before logging in.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Resend',
              onPressed: () async {
                await userCredential.user!.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Verification email sent!')),
                );
              },
            ),
          ),
        );
        await _auth.signOut();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home page
      Navigator.of(context).pushReplacementNamed('/home');
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
          errorMessage = 'Login failed. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email first')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent!'),
          backgroundColor: Colors.green,
        ),
      );
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
          errorMessage = 'Failed to send reset email.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          // โลโก้ Positioned
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

          // กล่องข้อมูล login
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // หัวข้อ Login + ไอคอน
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

                  // Email
                  _buildTextField(
                    controller: _emailController,
                    iconWidget: Image.asset(
                      'assets/icons/profile.png',
                      width: 35,
                      height: 35,
                    ),
                    hintText: 'Email',
                  ),
                  const SizedBox(height: 15),

                  // Password
                  _buildTextField(
                    controller: _passwordController,
                    iconWidget: Image.asset(
                      'assets/icons/lock.png',
                      width: 35,
                      height: 35,
                    ),
                    hintText: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 15),

                  // Login with Google
                  ElevatedButton(
                    onPressed: () {
                      _signInWithGoogle();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC98993),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
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
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "I'm not a robot",
                          style: GoogleFonts.kanit(fontSize: 16),
                        ),
                        const Spacer(),
                        Image.asset(
                          'assets/icons/life.png',
                          width: 24,
                          height: 24,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ปุ่มสมัครสมาชิกและเข้าสู่ระบบ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegistrationScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF564843),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
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
                      ElevatedButton(
                        onPressed: isRobotChecked && !_isLoading
                            ? _signInWithEmailAndPassword
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF564843),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'เข้าสู่ระบบ',
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้าง TextField พร้อม Icon Asset
  Widget _buildTextField({
    required TextEditingController controller,
    required Widget iconWidget,
    required String hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.kanit(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: iconWidget,
        ),
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
      ),
    );
  }
}
