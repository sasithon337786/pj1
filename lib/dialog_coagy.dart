import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

void showAddCategoryDialog(
    BuildContext context,
    TextEditingController categoryController,
    // เปลี่ยน Function signature ให้กลับมารับแค่ File และ String
    Function(File, String) onComplete) {
  // <<< ไม่รับ ApiService แล้ว
  File? selectedImage;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFEFEAE3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Image.asset(
                  'assets/icons/magic-wand.png',
                  width: 30,
                  height: 30,
                ),
                const SizedBox(width: 8),
                Text(
                  'เพิ่มหมวดหมู่',
                  style: GoogleFonts.kanit(
                    fontSize: 22,
                    color: const Color(0xFF5B4436),
                  ),
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC98993),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    String categoryName = categoryController.text.trim();
                    if (categoryName.isNotEmpty && selectedImage != null) {
                      // เรียกใช้ onComplete โดยส่งแค่ File และ String
                      await onComplete(selectedImage!,
                          categoryName); // <<< ไม่ส่ง apiService แล้ว
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('กรุณาเลือกรูปภาพและใส่ชื่อหมวดหมู่'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Complete',
                    style: GoogleFonts.kanit(fontSize: 18, color: Colors.white),
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
