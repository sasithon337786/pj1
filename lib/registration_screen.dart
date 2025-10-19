import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:pj1/login.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  File? _image;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController birthdayController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 150,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('เลือกรูปภาพ',
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final pickedFile =
                          await picker.pickImage(source: ImageSource.camera);
                      if (pickedFile != null) {
                        setState(() {
                          _image = File(pickedFile.path);
                        });
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: Text('กล้อง', style: GoogleFonts.kanit()),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final pickedFile =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          _image = File(pickedFile.path);
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: Text('แกลเลอรี่', style: GoogleFonts.kanit()),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // อัปโหลดขึ้น Firebase Storage แล้วคืน download URL
  Future<String?> _uploadProfileImage(String userId, File imageFile) async {
    try {
      final random = Random();
      final randomNumber = random.nextInt(90000) + 10000;
      final fileName = '${userId}_$randomNumber.jpg';

      final bucket = Firebase.app().options.storageBucket;
      if (bucket == null || bucket.isEmpty) {
        debugPrint('🔥 storageBucket is not set in Firebase options');
        return null;
      }

      final fullGsUrl = 'gs://$bucket/profile_images/$fileName';
      final ref = FirebaseStorage.instance.refFromURL(fullGsUrl);

      final snapshot = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (snapshot.state != TaskState.success) {
        debugPrint('❌ Upload failed: state=${snapshot.state}');
        return null;
      }

      await ref.getMetadata();
      final url = await ref.getDownloadURL();
      debugPrint('✅ Uploaded OK -> bucket=${ref.bucket}, path=${ref.fullPath}');
      debugPrint('✅ URL: $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint('🔥 FirebaseException [${e.code}] ${e.message}');
      return null;
    } catch (e) {
      debugPrint('🔥 Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> _registerUser() async {
    // ✅ ต้องเลือกรูปก่อน
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาใส่รูปภาพโปรไฟล์ของคุณ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านไม่ตรงกัน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = emailController.text.trim().toLowerCase(); // normalize

      // 1) อัปโหลดรูปไป Firebase Storage ก่อน (ถ้ามีรูป)
      String? photoURL;
      if (_image != null) {
        photoURL = await _uploadProfileImage(email, _image!);
      }

      // 2) ส่ง JSON ไป backend
      final uri = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/auth/registerwithemailpassword');

      final body = <String, dynamic>{
        'email': email,
        'password': passwordController.text.trim(),
        'username': nameController.text.trim(),
        'birthday': birthdayController.text.trim(),
        if (photoURL != null) 'photoURL': photoURL,
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      dynamic resBody;
      try {
        resBody = jsonDecode(response.body);
      } catch (_) {
        resBody = {'message': 'ไม่สามารถอ่านคำตอบจากเซิร์ฟเวอร์ได้'};
      }

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resBody['message'] ?? 'สมัครสมาชิกสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resBody['message'] ?? 'สมัครสมาชิกไม่สำเร็จ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('การเชื่อมต่อหมดเวลา โปรดลองใหม่อีกครั้ง'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF564843),
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF564843),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6D2CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      'สมัครสมาชิก',
                      style: GoogleFonts.kanit(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: nameController,
                      iconWidget: Image.asset(
                        'assets/icons/profile.png',
                        width: 30,
                        height: 30,
                      ),
                      hintText: 'ชื่อ-นามสกุล',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกชื่อ-นามสกุล';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: emailController,
                      iconWidget: Image.asset(
                        'assets/icons/email.png',
                        width: 30,
                        height: 30,
                      ),
                      hintText: 'อีเมล',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกอีเมล';
                        }
                        final email = value.trim().toLowerCase();

                        // เช็กฟอร์แมตอีเมลทั่วไป
                        final basicEmailOk =
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email);
                        if (!basicEmailOk) {
                          return 'รูปแบบอีเมลไม่ถูกต้อง';
                        }
                        // ✅ บังคับลงท้าย .com เท่านั้น
                        if (!email.endsWith('.com')) {
                          return 'อีเมลต้องลงท้ายด้วย .com เท่านั้น';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: passwordController,
                      iconWidget: Image.asset(
                        'assets/icons/pass.png',
                        width: 30,
                        height: 30,
                      ),
                      hintText: 'รหัสผ่าน',
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกรหัสผ่าน';
                        }
                        if (value.length < 6) {
                          return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: confirmPasswordController,
                      iconWidget: Image.asset(
                        'assets/icons/lock.png',
                        width: 30,
                        height: 30,
                      ),
                      hintText: 'ยืนยันรหัสผ่าน',
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณายืนยันรหัสผ่าน';
                        }
                        if (value != passwordController.text) {
                          return 'รหัสผ่านไม่ตรงกัน';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: birthdayController,
                      iconWidget: Image.asset(
                        'assets/icons/age.png',
                        width: 30,
                        height: 30,
                      ),
                      hintText: 'Birthday',
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          birthdayController.text =
                              "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                        }
                      },
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF564843),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'สมัครสมาชิก',
                                style: GoogleFonts.kanit(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'มีบัญชีแล้ว? เข้าสู่ระบบ',
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required Widget iconWidget,
    required String hintText,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
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
        fillColor: const Color(0xFFD08C94),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: GoogleFonts.kanit(
          color: Colors.red[300],
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    birthdayController.dispose();
    super.dispose();
  }
}
