import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pj1/Services/ApiService.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/registration_screen.dart';

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
      // Clear any existing sign-in state
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Configure GoogleSignIn with proper settings
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'openid',
        ],
        // เพิ่ม hostedDomain หากจำเป็น (สำหรับ G Suite domains)
        // hostedDomain: 'your-domain.com',
      );

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      print('Google User: ${googleUser.email}'); // Debug log

      // Obtain the auth details with proper error handling
      GoogleSignInAuthentication? googleAuth;

      try {
        // Force refresh the authentication
        await googleUser.clearAuthCache();
        googleAuth = await googleUser.authentication;

        print(
            'Access Token: ${googleAuth.accessToken != null ? "Present" : "Null"}');
        print('ID Token: ${googleAuth.idToken != null ? "Present" : "Null"}');

        // ตรวจสอบว่ามี tokens หรือไม่
        if (googleAuth.accessToken == null && googleAuth.idToken == null) {
          // ลองใช้วิธีอื่นในการรับ tokens
          print('Attempting alternative token retrieval...');

          // Sign out และ sign in ใหม่
          await googleSignIn.signOut();
          final GoogleSignInAccount? retryUser = await googleSignIn.signIn();

          if (retryUser != null) {
            googleAuth = await retryUser.authentication;
            print(
                'Retry - Access Token: ${googleAuth.accessToken != null ? "Present" : "Null"}');
            print(
                'Retry - ID Token: ${googleAuth.idToken != null ? "Present" : "Null"}');
          }
        }
      } catch (authError) {
        print('Authentication error: $authError');
        throw Exception('Failed to authenticate with Google: $authError');
      }

      if (googleAuth == null ||
          (googleAuth.accessToken == null && googleAuth.idToken == null)) {
        throw Exception('No authentication tokens received from Google');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // ตรวจสอบว่าการ sign in สำเร็จหรือไม่
      if (userCredential.user == null) {
        throw Exception('Failed to sign in with Google');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home page
      Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      print(
          'FirebaseAuthException: ${e.code} - ${e.message}'); // เพิ่ม debug log

      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credential. Please try again.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Google sign-in is not enabled. Please contact support.';
          break;
        default:
          errorMessage = 'Google sign-in failed: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // เพิ่ม detailed error logging
      print('Unexpected error during Google sign-in: $e');
      print('Error type: ${e.runtimeType}');

      String errorMessage = 'An unexpected error occurred.';

      // ตรวจสอบ error types แบบละเอียดขึ้น
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('google')) {
        errorMessage = 'Google sign-in service error. Please try again.';
      } else if (e.toString().contains('token')) {
        errorMessage = 'Authentication token error. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
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
