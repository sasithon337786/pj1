import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  File? _image;
  final picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController birthdayController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD08C94),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            // รูปภาพโปรไฟล์
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF4F3A35),
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 30),

            // กล่องข้อมูล
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFECDCD4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'Registeration',
                    style: GoogleFonts.kanit(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  _buildTextField(
                    controller: nameController,
                    iconWidget: Image.asset(
                      'assets/icons/lifestyle.png',
                      width: 24,
                      height: 24,
                    ),
                    hintText: 'Name',
                  ),

                  const SizedBox(height: 15),

                  // Email
                  _buildTextField(
                    controller: emailController,
                    iconWidget: Image.asset(
                      'assets/icons/lifestyle.png',
                      width: 24,
                      height: 24,
                    ),
                    hintText: 'Email',
                  ),

                  const SizedBox(height: 15),

                  // Password
                  _buildTextField(
                    controller: passwordController,
                    iconWidget: Image.asset(
                      'assets/icons/lifestyle.png',
                      width: 24,
                      height: 24,
                    ),
                    hintText: 'Password',
                    obscureText: true,
                  ),

                  const SizedBox(height: 15),

                  // Confirm Password
                  _buildTextField(
                    controller: confirmPasswordController,
                    iconWidget: Image.asset(
                      'assets/icons/lifestyle.png',
                      width: 24,
                      height: 24,
                    ),
                    hintText: 'Confirm Password',
                    obscureText: true,
                  ),

                  const SizedBox(height: 15),

                  // Birthday
                  _buildTextField(
                    controller: birthdayController,
                    iconWidget: Image.asset(
                      'assets/icons/lifestyle.png',
                      width: 24,
                      height: 24,
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

                  // ปุ่มสมัครสมาชิก
                  ElevatedButton(
                    onPressed: () {
                      // ตรงนี้ไว้ handle register
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F3A35),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'สมัครสมาชิก',
                      style: GoogleFonts.kanit(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสร้าง TextField พร้อม Icon Asset
  Widget _buildTextField({
    required TextEditingController controller,
    required Widget iconWidget,
    required String hintText,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
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
      ),
    );
  }
}
