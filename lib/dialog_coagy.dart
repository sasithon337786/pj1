import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:pj1/constant/api_endpoint.dart';
import 'dart:math';

import 'package:pj1/widgets/error_notifier.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  File? selectedImage;
  final categoryController = TextEditingController();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool isLoading = false;

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

  Future<void> _createCategory() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
  final categoryName = categoryController.text.trim();

  // 🔎 validate เบื้องต้น
  if (categoryName.isEmpty || selectedImage == null || uid == null || idToken == null) {
    if (mounted) ErrorNotifier.showSnack(context, 'กรุณาเลือกภาพและใส่ชื่อหมวดหมู่');
    return;
  }

  setState(() => isLoading = true);
  try {
    // 🖼️ อัปโหลดรูป
    final imageUrl = await _uploadCategoryImage(uid, selectedImage!);
    if (imageUrl == null) {
      if (mounted) ErrorNotifier.showSnack(context, 'อัปโหลดรูปภาพไม่สำเร็จ');
      return;
    }

    // 🔑 เลือก endpoint ตาม role
    final role = await _getUserRole(uid);
    if (role == null) {
      if (mounted) ErrorNotifier.showSnack(context, 'ไม่สามารถตรวจสอบสิทธิ์ผู้ใช้ได้');
      return;
    }

    final url = role == 'admin'
        ? Uri.parse('${ApiEndpoints.baseUrl}/api/category/addDefaultCategory')
        : Uri.parse('${ApiEndpoints.baseUrl}/api/category/createCate');

    // 🚀 ยิง API
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'uid': uid,
        'cate_name': categoryName,
        'cate_pic': imageUrl,
      }),
    );

    if (resp.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มหมวดหมู่สำเร็จ')),
      );
      Navigator.pop(context, true);
    } else {
      // ⛳ ส่ง error จาก BE ไปที่ widget
      final message = _extractBackendMessage(resp.body) ?? 'บันทึกหมวดหมู่ล้มเหลว';
      if (mounted) ErrorNotifier.showSnack(context, message);
    }
  } catch (e) {
    if (mounted) ErrorNotifier.showSnack(context, 'เกิดข้อผิดพลาด: $e');
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}

/// ดึงข้อความ error จาก body (รองรับไม่ใช่ JSON / ไม่มี message)
String? _extractBackendMessage(String body) {
  try {
    final data = jsonDecode(body);
    if (data is Map) {
      // รองรับทั้ง {message}, {error}, {code+message}
      if (data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
        return data['message'] as String;
      }
      if (data['error'] is String && (data['error'] as String).trim().isNotEmpty) {
        return data['error'] as String;
      }
    }
  } catch (_) {
    // body ไม่ใช่ JSON → ส่งทั้งสตริงกลับไปเลย (บาง BE อาจส่ง plain text)
    if (body.trim().isNotEmpty) return body.trim();
  }
  return null;
}

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFEFEAE3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Image.asset('assets/icons/magic-wand.png', width: 30, height: 30),
          const SizedBox(width: 8),
          Text('เพิ่มหมวดหมู่', style: GoogleFonts.kanit(fontSize: 22)),
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
              ),
              child: selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(selectedImage!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.add_photo_alternate,
                      size: 50, color: Colors.white),
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
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC98993),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _createCategory,
                  child: Text('Complete',
                      style:
                          GoogleFonts.kanit(fontSize: 18, color: Colors.white)),
                ),
        ],
      ),
    );
  }
}
