import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/services/auth_service.dart';
import 'package:pj1/widgets/custom_text_field.dart';
import 'package:pj1/widgets/avatar_picker.dart';
import 'package:pj1/screens/login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  File? _image;
  bool _isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final birthdayController = TextEditingController();

  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar('รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _authService.registerUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        birthday: birthdayController.text.trim(),
        image: _image,
      );

      if (res['status'] == 201) {
        _showSnackBar(res['body']['message'] ?? 'สมัครสมาชิกสำเร็จ!',
            color: Colors.green);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        _showSnackBar(res['body']['message'] ?? 'สมัครสมาชิกไม่สำเร็จ');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
              AvatarPicker(onImagePicked: (file) => setState(() => _image = file)),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6D2CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text("สมัครสมาชิก",
                        style: GoogleFonts.kanit(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: nameController,
                      icon: Image.asset('assets/icons/profile.png', width: 30, height: 30),
                      hintText: 'ชื่อ-นามสกุล',
                      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อ' : null,
                    ),
                    const SizedBox(height: 15),

                    CustomTextField(
                      controller: emailController,
                      icon: Image.asset('assets/icons/email.png', width: 30, height: 30),
                      hintText: 'อีเมล',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v != null && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)
                              ? null
                              : 'กรุณากรอกอีเมลให้ถูกต้อง',
                    ),
                    const SizedBox(height: 15),

                    CustomTextField(
                      controller: passwordController,
                      icon: Image.asset('assets/icons/pass.png', width: 30, height: 30),
                      hintText: 'รหัสผ่าน',
                      obscureText: true,
                      validator: (v) =>
                          v != null && v.length >= 6 ? null : 'รหัสผ่านต้อง >= 6 ตัว',
                    ),
                    const SizedBox(height: 15),

                    CustomTextField(
                      controller: confirmPasswordController,
                      icon: Image.asset('assets/icons/lock.png', width: 30, height: 30),
                      hintText: 'ยืนยันรหัสผ่าน',
                      obscureText: true,
                      validator: (v) =>
                          v != passwordController.text ? 'รหัสผ่านไม่ตรงกัน' : null,
                    ),
                    const SizedBox(height: 15),

                    CustomTextField(
                      controller: birthdayController,
                      icon: Image.asset('assets/icons/age.png', width: 30, height: 30),
                      hintText: 'วันเกิด',
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
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
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Text("สมัครสมาชิก",
                                style: GoogleFonts.kanit(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("มีบัญชีแล้ว? เข้าสู่ระบบ",
                          style: GoogleFonts.kanit(color: Colors.white, fontSize: 16)),
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
}
