import 'dart:convert';

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
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // สร้าง credential สำหรับ Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ล็อกอินเข้า Firebase
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // 🔐 รับ Firebase ID Token เพื่อส่งไป Backend
      final idToken = await user.getIdToken();

      // TODO: ส่ง idToken ไป Backend (ตัวอย่างด้านล่าง)
      final response = await http.post(
        Uri.parse(ApiEndpoints.baseUrl + '/api/auth/loginwithgoogle'),
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
    print('ปุ่มถูกกด: กำลังเข้าสู่ระบบ...');
    if (!_formKey.currentState!.validate()) {
      print('การตรวจสอบฟอร์มล้มเหลว');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (userCredential.user == null) {
        throw Exception("ไม่สามารถรับข้อมูลผู้ใช้จาก Firebase ได้");
      }

      // 2. หากการลงชื่อเข้าใช้กับ Firebase สำเร็จ ให้รับ Firebase ID Token
      String? idToken = await userCredential.user!.getIdToken();

      if (idToken == null) {
        throw Exception("ไม่สามารถรับ Firebase ID Token ได้");
      }
      print('Token===='+idToken);

      // 3. ส่ง Firebase ID Token ไปยัง Backend ของคุณ
      final backendResponse = await http.post(
        Uri.parse(ApiEndpoints.baseUrl +
            'api/auth/loginwithemail'), // Endpoint ของ Backend
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(<String, String>{
          'idToken': idToken,
        }),
      );

      if (!mounted) return;

      if (backendResponse.statusCode == 200) {
        final responseBody = jsonDecode(backendResponse.body);

        String? userRole = responseBody['role'];
        
        String message = responseBody['message'] ?? 'เข้าสู่ระบบสำเร็จ!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );

        if (userRole == 'member') {
          Navigator.of(context)
              .pushReplacementNamed('/mainuser'); // ไปที่หน้าหลักของสมาชิก
        } else if (userRole == 'admin') {
          Navigator.of(context).pushReplacementNamed(
              '/mainadmin'); // ไปที่หน้าหลักของผู้ดูแลระบบ
        } else {
          // กรณีที่บทบาทผู้ใช้ไม่ชัดเจนหรือไม่ตรงกับที่คาดไว้
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('บทบาทผู้ใช้ไม่ชัดเจน กรุณาติดต่อผู้ดูแลระบบ'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Backend ตอบกลับมาว่าไม่สำเร็จ (สถานะ HTTP อื่นๆ เช่น 401, 400, 500)
        final errorBody = jsonDecode(backendResponse.body);
        // กำหนดข้อความแสดงข้อผิดพลาด โดยใช้ค่าจาก backend ถ้ามี หรือข้อความเริ่มต้น
        String errorMessage =
            errorBody['message'] ?? 'เข้าสู่ระบบล้มเหลว โปรดลองอีกครั้ง';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // ป้องกันการใช้ BuildContext ข้าม async gaps: ตรวจสอบ mounted
      if (!mounted) return;
      // จัดการข้อผิดพลาดเฉพาะที่มาจาก Firebase Authentication (เช่น ลงชื่อเข้าใช้ไม่สำเร็จที่ฝั่งไคลเอ็นต์)
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'ไม่พบผู้ใช้ด้วยอีเมลนี้';
          break;
        case 'wrong-password':
          errorMessage = 'รหัสผ่านผิด';
          break;
        case 'invalid-email':
          errorMessage = 'ที่อยู่อีเมลไม่ถูกต้อง';
          break;
        case 'user-disabled':
          errorMessage = 'บัญชีผู้ใช้นี้ถูกปิดใช้งาน';
          break;
        case 'too-many-requests':
          errorMessage =
              'พยายามลงชื่อเข้าใช้ล้มเหลวหลายครั้งเกินไป โปรดลองอีกครั้งในภายหลัง';
          break;
        default:
          errorMessage =
              'การลงชื่อเข้าใช้ Firebase ล้มเหลว: ${e.message ?? e.code}'; // ใช้ e.code ถ้า message เป็น null
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      print(
          'FirebaseAuthException: ${e.code} - ${e.message}'); // เพิ่ม print สำหรับ debug
    } on http.ClientException catch (e) {
      // ป้องกันการใช้ BuildContext ข้าม async gaps: ตรวจสอบ mounted
      if (!mounted) return;
      // จัดการข้อผิดพลาดเครือข่ายเมื่อสื่อสารกับ Backend ของคุณ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'ข้อผิดพลาดเครือข่าย: ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ (${e.message})'),
          backgroundColor: Colors.red,
        ),
      );
      print('HTTP Client Exception: ${e.message}');
    } catch (e) {
      // ป้องกันการใช้ BuildContext ข้าม async gaps: ตรวจสอบ mounted
      if (!mounted) return;
      // ดักจับข้อผิดพลาดอื่นๆ ที่ไม่คาดคิด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิด: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Unexpected Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false; // ซ่อนสถานะกำลังโหลด
      });
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
            // **สำคัญมาก: ห่อหุ้มด้วย Form widget ที่นี่**
            child: Form(
              key: _formKey, // กำหนด GlobalKey ให้กับ Form
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

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      iconWidget: Image.asset(
                        'assets/icons/profile.png',
                        width: 35,
                        height: 35,
                      ),
                      hintText: 'Email',
                      keyboardType:
                          TextInputType.emailAddress, // เพิ่มประเภทคีย์บอร์ด
                      validator: (value) {
                        // **สำคัญ: ส่ง validator เข้าไป**
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกอีเมล';
                        }
                        if (!value.contains('@')) {
                          return 'รูปแบบอีเมลไม่ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Password Field
                    _buildTextField(
                      controller: _passwordController,
                      iconWidget: Image.asset(
                        'assets/icons/lock.png',
                        width: 35,
                        height: 35,
                      ),
                      hintText: 'Password',
                      obscureText: true,
                      validator: (value) {
                        // **สำคัญ: ส่ง validator เข้าไป**
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกรหัสผ่าน';
                        }
                        if (value.length < 6) {
                          // ตัวอย่าง: รหัสผ่านต้องมีอย่างน้อย 6 ตัว
                          return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                        }
                        return null;
                      },
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
                                builder: (context) =>
                                    const RegistrationScreen(),
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
                          onPressed: _isLoading
                              ? null // ปิดการใช้งานปุ่มขณะโหลด
                              : _signInWithEmailAndPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF564843),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ) // แสดง loading indicator
                              : Text(
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
            ), // <-- สิ้นสุด Form widget ที่นี่
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้าง TextField พร้อม Icon Asset
  // **สำคัญ: เปลี่ยนเป็น TextFormField และเพิ่ม validator parameter**
  Widget _buildTextField({
    required TextEditingController controller,
    required Widget iconWidget,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType =
        TextInputType.text, // เพิ่มสำหรับระบุประเภทคีย์บอร์ด
    String? Function(String?)? validator, // **เพิ่ม parameter นี้**
  }) {
    return TextFormField(
      // **เปลี่ยนจาก TextField เป็น TextFormField**
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType, // กำหนดประเภทคีย์บอร์ด
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
        // **เพิ่ม errorStyle เพื่อให้ข้อความ validator ไม่ซ่อน icon/text field**
        errorStyle: GoogleFonts.kanit(
          color: Colors.red,
          fontSize: 12,
        ),
        // **ปรับ padding เพื่อให้ error text แสดงผลได้ดีขึ้น**
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      validator: validator, // **ส่ง validator ที่รับมาไปให้ TextFormField**
    );
  }
}
