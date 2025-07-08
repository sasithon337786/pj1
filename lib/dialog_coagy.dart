import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:pj1/constant/api_endpoint.dart'; // ✅ เปลี่ยนให้ถูกกับโปรเจกต์ของคุณ
import 'dart:math';

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
      final randomNumber =
          random.nextInt(90000) + 10000; // เลข 5 หลัก 10000-99999

      final ref = _storage
          .ref()
          .child('category_pics')
          .child('${userId}_$randomNumber.jpg'); // ตั้งชื่อไฟล์แบบใหม่

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading category image: $e');
      return null;
    }
  }

  Future<void> _createCategory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String categoryName = categoryController.text.trim();
    print(uid);
    if (categoryName.isNotEmpty && selectedImage != null && uid != null) {
      setState(() => isLoading = true);
      final imageUrl = await _uploadCategoryImage(uid, selectedImage!);
      print('Image URL: $imageUrl');
      if (imageUrl != null) {
        final response = await http.post(
          Uri.parse('${ApiEndpoints.baseUrl}/api/category/createCate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid': uid,
            'cate_name': categoryName,
            'cate_pic': imageUrl,
          }),
        );

        if (response.statusCode == 200) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เพิ่มหมวดหมู่สำเร็จ')),
            );
            Navigator.pop(context, true); // ✅ ส่ง true กลับ
          }
        } else {
          final message =
              jsonDecode(response.body)['message'] ?? 'บันทึกหมวดหมู่ล้มเหลว';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
      setState(() => isLoading = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพและใส่ชื่อหมวดหมู่')),
      );
    }
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
                  child:
                      Text('Complete', style: GoogleFonts.kanit(fontSize: 18)),
                ),
        ],
      ),
    );
  }
}
