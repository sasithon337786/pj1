import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/add.dart'; // ✅ เพิ่ม import นี้เข้ามา
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/dialog_coagy.dart';
import 'package:pj1/mains.dart'; // ตรวจสอบ path ของ Category class ให้ถูกต้อง
import 'package:pj1/edit_category_dialog.dart';

class ManageCategoriesDialog extends StatefulWidget {
  final VoidCallback onCategoriesUpdated;

  const ManageCategoriesDialog({super.key, required this.onCategoriesUpdated});

  @override
  State<ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<ManageCategoriesDialog> {
  List<Category> userCategories = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserCategoriesForManagement();
  }

  Future<void> _loadUserCategoriesForManagement() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        errorMessage = 'ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่';
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/category/getCategory?uid=$uid'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categoriesData = (data as List).map((item) {
          return Category(
            id: int.tryParse(item['cate_id'].toString()),
            iconPath: item['cate_pic'],
            label: item['cate_name'],
            isNetworkImage: true,
          );
        }).toList();

        setState(() {
          userCategories = categoriesData;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'ไม่สามารถโหลดหมวดหมู่ได้: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาดในการโหลดหมวดหมู่: $e';
        isLoading = false;
      });
      print('Error loading categories for management: $e');
    }
  }

  Future<void> _deleteCategory(int? categoryId, String categoryName) async {
    if (categoryId == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่')),
      );
      return;
    }

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFEFEAE3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('ยืนยันการลบ', style: GoogleFonts.kanit()),
          content: Text('คุณต้องการลบหมวดหมู่ "$categoryName" ใช่หรือไม่?', style: GoogleFonts.kanit()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('ยกเลิก', style: GoogleFonts.kanit(color: Color(0xFF564843))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('ลบ', style: GoogleFonts.kanit(color: Color(0xFFC98993))),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        isLoading = true; // แสดง loading ก่อนลบ
      });
      try {
        final response = await http.post(
          Uri.parse('${ApiEndpoints.baseUrl}/api/category/deleteCategory'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid': uid,
            'cate_id': categoryId,
          }),
        );

        if (response.statusCode == 200) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ลบหมวดหมู่ "$categoryName" สำเร็จ')),
            );
          }
          _loadUserCategoriesForManagement(); // โหลดใหม่หลังจากลบ
          widget.onCategoriesUpdated.call(); // แจ้งหน้าหลักให้อัปเดตหมวดหมู่
        } else {
          final message = jsonDecode(response.body)['message'] ?? 'ลบหมวดหมู่ล้มเหลว';
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')),
          );
        }
      } finally {
        setState(() {
          isLoading = false; // ซ่อน loading หลังลบเสร็จ
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFEFEAE3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Image.asset('assets/icons/winking-face.png', width: 30, height: 30),
          const SizedBox(width: 8),
          Text('จัดการหมวดหมู่', style: GoogleFonts.kanit(fontSize: 22, color: const Color(0xFF564843))),
        ],
      ),
      content: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC98993)))
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: GoogleFonts.kanit(color: Colors.red)))
              : userCategories.isEmpty
                  ? Center(child: Text('คุณยังไม่มีหมวดหมู่ที่สร้างเอง', style: GoogleFonts.kanit(color: Colors.grey)))
                  : SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: userCategories.length,
                        itemBuilder: (context, index) {
                          final category = userCategories[index];
                          return Card(
                            color: const Color(0xFFF3E1E1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: category.isNetworkImage
                                  ? ClipOval(
                                      child: Image.network(
                                        category.iconPath,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      ),
                                    )
                                  : Image.asset(category.iconPath, width: 40, height: 40),
                              title: Text(
                                category.label,
                                style: GoogleFonts.kanit(fontSize: 18, color: const Color(0xFF564843)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF564843)),
                                    onPressed: () async {
                                      final bool? result = await showDialog(
                                        context: context,
                                        builder: (context) => EditCategoryDialog(category: category),
                                      );
                                      if (result == true) {
                                        _loadUserCategoriesForManagement();
                                        widget.onCategoriesUpdated.call();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Color(0xFFC98993)),
                                    onPressed: () => _deleteCategory(category.id, category.label),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      actions: [
        // ✅ เพิ่มปุ่ม "เพิ่มหมวดหมู่" ตรงนี้
        Align(
          alignment: Alignment.center, // จัดให้อยู่ซ้ายของปุ่ม "ปิด"
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0), // เพิ่ม padding เล็กน้อย
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => const AddCategoryDialog(),
                );
                if (result == true) {
                  // ถ้าเพิ่มหมวดหมู่สำเร็จ ให้โหลดรายการหมวดหมู่ใหม่
                  _loadUserCategoriesForManagement();
                  widget.onCategoriesUpdated.call(); // แจ้งหน้าหลักให้อัปเดต
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF564843), // สีเดียวกับปุ่มอื่นๆ
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 20), // ไอคอนเพิ่ม
              label: Text(
                'เพิ่มหมวดหมู่',
                style: GoogleFonts.kanit(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
        const Spacer(), // เพิ่ม Spacer เพื่อดันปุ่ม "ปิด" ไปทางขวา
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('ปิด', style: GoogleFonts.kanit(color: const Color(0xFF564843), fontSize: 16)),
        ),
      ],
    );
  }
}