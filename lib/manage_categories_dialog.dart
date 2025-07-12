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

    // 🔍 ตรวจสอบ role ก่อน
    final role = await _getUserRole(uid);
    if (role == null) {
      setState(() {
        errorMessage = 'ไม่สามารถตรวจสอบสิทธิ์ผู้ใช้ได้';
        isLoading = false;
      });
      return;
    }

    // 🌐 เลือก API ตาม role
    final Uri url = role == 'admin'
        ? Uri.parse('${ApiEndpoints.baseUrl}/api/admin/getDefaultCategories')
        : Uri.parse(
            '${ApiEndpoints.baseUrl}/api/category/getCategory?uid=$uid');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 💡 รองรับทั้งกรณีที่ API ส่งมาเป็น List ตรง ๆ หรือมี key เช่น "categories"
        final List categoriesRaw =
            data is List ? data : (data['categories'] ?? []);

        final categoriesData = categoriesRaw.map((item) {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('ยืนยันการลบ', style: GoogleFonts.kanit()),
          content: Text('คุณต้องการลบหมวดหมู่ "$categoryName" ใช่หรือไม่?',
              style: GoogleFonts.kanit()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('ยกเลิก',
                  style: GoogleFonts.kanit(color: Color(0xFF564843))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('ลบ',
                  style: GoogleFonts.kanit(color: Color(0xFFC98993))),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        isLoading = true;
      });

      try {
        // ✅ ตรวจสอบ role ก่อน
        final role = await _getUserRole(uid);
        if (role == null) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถตรวจสอบสิทธิ์ผู้ใช้ได้')),
          );
          return;
        }

        // 🌐 เลือก URL ตาม role
        final Uri url = role == 'admin'
            ? Uri.parse(
                '${ApiEndpoints.baseUrl}/api/admin/deleteDefaultCategory')
            : Uri.parse('${ApiEndpoints.baseUrl}/api/category/deleteCategory');

        final response = await http.post(
          url,
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
          _loadUserCategoriesForManagement();
          widget.onCategoriesUpdated.call();
        } else {
          final message =
              jsonDecode(response.body)['message'] ?? 'ลบหมวดหมู่ล้มเหลว';
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
          isLoading = false;
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
          Text('จัดการหมวดหมู่',
              style: GoogleFonts.kanit(
                  fontSize: 22, color: const Color(0xFF564843))),
        ],
      ),
      content: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC98993)))
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!,
                      style: GoogleFonts.kanit(color: Colors.red)))
              : userCategories.isEmpty
                  ? Center(
                      child: Text('คุณยังไม่มีหมวดหมู่ที่สร้างเอง',
                          style: GoogleFonts.kanit(color: Colors.grey)))
                  : SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: userCategories.length,
                        itemBuilder: (context, index) {
                          final category = userCategories[index];
                          return Card(
                            color: const Color(0xFFF3E1E1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: category.isNetworkImage
                                  ? ClipOval(
                                      child: Image.network(
                                        category.iconPath,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image,
                                                    size: 40,
                                                    color: Colors.grey),
                                      ),
                                    )
                                  : Image.asset(category.iconPath,
                                      width: 40, height: 40),
                              title: Text(
                                category.label,
                                style: GoogleFonts.kanit(
                                    fontSize: 18,
                                    color: const Color(0xFF564843)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Color(0xFF564843)),
                                    onPressed: () async {
                                      final bool? result = await showDialog(
                                        context: context,
                                        builder: (context) =>
                                            EditCategoryDialog(
                                                category: category),
                                      );
                                      if (result == true) {
                                        _loadUserCategoriesForManagement();
                                        widget.onCategoriesUpdated.call();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Color(0xFFC98993)),
                                    onPressed: () => _deleteCategory(
                                        category.id, category.label),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      actions: [
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => const AddCategoryDialog(),
                );
                if (result == true) {
                  _loadUserCategoriesForManagement();
                  widget.onCategoriesUpdated.call();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF564843),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: Text(
                'เพิ่มหมวดหมู่',
                style: GoogleFonts.kanit(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('ปิด',
              style: GoogleFonts.kanit(
                  color: const Color(0xFF564843), fontSize: 16)),
        ),
      ],
    );
  }
}
