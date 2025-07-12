// lib/edit_category_dialog.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pj1/add.dart';
import 'dart:math';

import 'package:pj1/constant/api_endpoint.dart';

class EditCategoryDialog extends StatefulWidget {
  final Category category;

  const EditCategoryDialog({super.key, required this.category});

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  File? selectedImage;
  late TextEditingController categoryController;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool isLoading = false;
  String? currentImageUrl;

  @override
  void initState() {
    super.initState();

    categoryController = TextEditingController(text: widget.category.label);

    currentImageUrl = widget.category.iconPath;
  }

  @override
  void dispose() {
    categoryController.dispose();
    super.dispose();
  }

  Future<String?> _getUserRole(String uid) async {
    // Example: Make an API call to get the user's role
    // Replace with your actual API call
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiEndpoints.baseUrl}/api/auth/getRole?uid=$uid'), // Example API route
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role']; // Assuming the response has a 'role' field
      } else {
        print('Failed to get user role: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<String?> _uploadCategoryImage(String userId, File imageFile) async {
    try {
      final random = Random();
      final randomNumber = random.nextInt(90000) + 10000;

      final ref = _storage
          .ref()
          .child('category_pics')
          .child('${userId}_$randomNumber.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading category image: $e');
      return null;
    }
  }

  Future<void> _updateCategory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String categoryName = categoryController.text.trim();
    int? categoryId = widget.category.id;

    if (categoryId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบรหัสหมวดหมู่สำหรับการแก้ไข')),
        );
      }
      return;
    }

    if (categoryName.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาใส่ชื่อหมวดหมู่')),
        );
      }
      return;
    }

    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่')),
        );
      }
      return;
    }

    setState(() => isLoading = true);
    String? finalImageUrl = currentImageUrl;

    // 📤 Upload รูปใหม่ถ้ามี
    if (selectedImage != null) {
      finalImageUrl = await _uploadCategoryImage(uid, selectedImage!);
      if (finalImageUrl == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถอัปโหลดรูปภาพใหม่ได้')),
          );
        }
        setState(() => isLoading = false);
        return;
      }
    } else if (finalImageUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกรูปภาพสำหรับหมวดหมู่')),
        );
      }
      setState(() => isLoading = false);
      return;
    }

    try {
      // ✅ ตรวจสอบ role
      final role = await _getUserRole(uid);
      if (role == null) {
        setState(() => isLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถตรวจสอบสิทธิ์ผู้ใช้ได้')),
          );
        }
        return;
      }

      // 🌐 เลือก API URL ตาม role
      final Uri url = role == 'admin'
          ? Uri.parse('${ApiEndpoints.baseUrl}/api/admin/updateDefaultCategory')
          : Uri.parse('${ApiEndpoints.baseUrl}/api/category/updateCategory');

      // 🛰️ ส่งคำขอไปยัง backend
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'cate_id': categoryId,
          'cate_name': categoryName,
          'cate_pic': finalImageUrl,
        }),
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แก้ไขหมวดหมู่สำเร็จ')),
          );
          Navigator.pop(context, true);
        }
      } else {
        final message =
            jsonDecode(response.body)['message'] ?? 'แก้ไขหมวดหมู่ล้มเหลว';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e) {
      print('Error updating category: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFEFEAE3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Image.asset(
            'assets/icons/winking-face.png',
            width: 30,
            height: 30,
          ),
          const SizedBox(width: 8),
          Text('แก้ไขหมวดหมู่',
              style: GoogleFonts.kanit(
                  fontSize: 22, color: const Color(0xFF564843))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              final pickedFile =
                  await ImagePicker().pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() {
                  selectedImage = File(pickedFile.path);
                });
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE6D2CD),
                borderRadius: BorderRadius.circular(50),
                image: selectedImage != null
                    ? DecorationImage(
                        image: FileImage(selectedImage!), fit: BoxFit.cover)
                    : (currentImageUrl != null && currentImageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(currentImageUrl!),
                            fit: BoxFit.cover)
                        : null),
              ),
              child: selectedImage == null &&
                      (currentImageUrl == null || currentImageUrl!.isEmpty)
                  ? const Icon(Icons.add_photo_alternate,
                      size: 50, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: categoryController,
            decoration: InputDecoration(
              hintText: 'ชื่อหมวดหมู่',
              filled: true,
              fillColor: const Color(0xFF564843),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            style: GoogleFonts.kanit(color: Colors.white),
          ),
          const SizedBox(height: 16),
          isLoading
              ? const CircularProgressIndicator(color: Color(0xFFC98993))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC98993),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _updateCategory,
                  child: Text('บันทึกการแก้ไข',
                      style:
                          GoogleFonts.kanit(fontSize: 18, color: Colors.white)),
                ),
        ],
      ),
    );
  }
}
