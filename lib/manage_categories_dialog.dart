import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// ✅ แก้ import ให้ชี้ไปยังไฟล์ที่ประกาศ Category (ปรับตามโปรเจกต์จริงของหนู)
import 'package:pj1/add.dart' show Category;

import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/dialog_coagy.dart';
import 'package:pj1/edit_category_dialog.dart';
// ถ้ามี AddCategoryDialog ในไฟล์อื่น อย่าลืม import ด้วย

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
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserCategoriesForManagement();
  }

  Future<String?> _getUserRole(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/getRole?uid=$uid'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role'];
      } else {
        debugPrint('Failed to get user role: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  Future<void> _loadUserCategoriesForManagement() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        errorMessage = 'ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่';
        isLoading = false;
      });
      return;
    }

    final idToken = await user.getIdToken(true);

    // ตรวจสอบ role
    final role = await _getUserRole(user.uid);
    if (role == null) {
      setState(() {
        errorMessage = 'ไม่สามารถตรวจสอบสิทธิ์ผู้ใช้ได้';
        isLoading = false;
      });
      return;
    }

    setState(() {
      userRole = role;
    });

    final Uri url = role == 'admin'
        ? Uri.parse('${ApiEndpoints.baseUrl}/api/category/getDefaultCategories')
        : Uri.parse(
            '${ApiEndpoints.baseUrl}/api/category/getCategory?uid=${user.uid}');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
          userCategories = categoriesData.cast<Category>();
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
    }
  }

  Future<void> _deleteCategory(int? categoryId, String categoryName) async {
    if (categoryId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่')),
      );
      return;
    }

    final idToken = await user.getIdToken(true);

    final bool? confirmDelete = await showDialog<bool>(
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
                  style: GoogleFonts.kanit(color: const Color(0xFF564843))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('ลบ',
                  style: GoogleFonts.kanit(color: const Color(0xFFC98993))),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() => isLoading = true);

      try {
        final role = await _getUserRole(user.uid);
        if (role == null) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถตรวจสอบสิทธิ์ผู้ใช้ได้')),
          );
          return;
        }

        final Uri url = role == 'admin'
            ? Uri.parse(
                '${ApiEndpoints.baseUrl}/api/category/deleteDefaultCategory')
            : Uri.parse('${ApiEndpoints.baseUrl}/api/category/deleteCategory');

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'uid': user.uid,
            'cate_id': categoryId,
          }),
        );

        if (response.statusCode == 200) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ลบหมวดหมู่ "$categoryName" สำเร็จ')),
            );
          }
          await _loadUserCategoriesForManagement();
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
        setState(() => isLoading = false);
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
          Text(
            'จัดการหมวดหมู่',
            style:
                GoogleFonts.kanit(fontSize: 22, color: const Color(0xFF564843)),
          ),
        ],
      ),

      // ✅ จัด layout ของปุ่มใน actions โดยไม่ต้องใช้ Spacer/Expanded
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

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
                      // ถ้าหน้าจอคับ ให้จำกัดความสูงสักหน่อย กัน overflow
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
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
                                trailing: userRole == 'admin'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Color(0xFF564843)),
                                            onPressed: () async {
                                              final bool? result =
                                                  await showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    EditCategoryDialog(
                                                        category: category),
                                              );
                                              if (result == true) {
                                                await _loadUserCategoriesForManagement();
                                                widget.onCategoriesUpdated
                                                    .call();
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
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

      actions: [
        if (userRole == 'admin')
          ElevatedButton.icon(
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => const AddCategoryDialog(),
              );
              if (result == true) {
                await _loadUserCategoriesForManagement();
                widget.onCategoriesUpdated.call();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF564843),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            label: Text('เพิ่มหมวดหมู่',
                style: GoogleFonts.kanit(color: Colors.white, fontSize: 16)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('ปิด',
              style: GoogleFonts.kanit(
                  color: const Color(0xFF564843), fontSize: 16)),
        ),
      ],
    );
  }
}
