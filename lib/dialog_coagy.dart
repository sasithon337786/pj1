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

void showAddCategoryDialog(
  BuildContext context,
  TextEditingController categoryController,
  Function(File, String)? onComplete, // ยังไม่ได้ใช้ แต่เผื่อในอนาคต
) {
  File? selectedImage;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;

          /// 📤 อัปโหลดภาพไป Firebase Storage
          Future<String?> _uploadCategoryImage(
              String userId, File imageFile) async {
            try {
              String fileName = path.basename(imageFile.path);
              final ref = _storage
                  .ref()
                  .child('category_pics')
                  .child(userId)
                  .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

              final snapshot = await ref.putFile(imageFile);
              return await snapshot.ref.getDownloadURL();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('อัปโหลดรูปภาพล้มเหลว: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return null;
            }
          }

          /// ➕ สร้างหมวดหมู่
          Future<void> _createCategory() async {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            String categoryName = categoryController.text.trim();

            if (categoryName.isNotEmpty &&
                selectedImage != null &&
                uid != null) {
              setState(() => isLoading = true);

              final imageUrl = await _uploadCategoryImage(uid, selectedImage!);

              if (imageUrl != null) {
                final response = await http.post(
                  Uri.parse('${ApiEndpoints.baseUrl}/api/category/createCategory'),
                  headers: {
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'uid': uid,
                    'cate_name': categoryName,
                    'cate_pic': imageUrl,
                  }),
                );

                if (response.statusCode == 200) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('เพิ่มหมวดหมู่สำเร็จ'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                } else {
                  final message = jsonDecode(response.body)['message'] ??
                      'บันทึกหมวดหมู่ล้มเหลว';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              setState(() => isLoading = false);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('กรุณาเลือกรูปภาพและใส่ชื่อหมวดหมู่'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFFEFEAE3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Image.asset('assets/icons/magic-wand.png',
                    width: 30, height: 30),
                const SizedBox(width: 8),
                Text(
                  'เพิ่มหมวดหมู่',
                  style:
                      GoogleFonts.kanit(fontSize: 22, color: Color(0xFF5B4436)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final pickedFile = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
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
                            child:
                                Image.file(selectedImage!, fit: BoxFit.cover),
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
                    hintStyle: GoogleFonts.kanit(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF564843),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: _createCategory,
                        child: Text(
                          'Complete',
                          style: GoogleFonts.kanit(
                              fontSize: 18, color: Colors.white),
                        ),
                      ),
              ],
            ),
          );
        },
      );
    },
  );
}
