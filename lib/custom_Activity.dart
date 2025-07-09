import 'dart:async';
import 'dart:convert';
import 'dart:io'; // สำหรับ File
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับ FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Cloud Firestore
import 'package:firebase_storage/firebase_storage.dart'; // สำหรับ Firebase Storage
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // สำหรับ ImagePicker

// ต้อง import ไฟล์ที่เกี่ยวข้องทั้งหมดที่ใช้ใน Bottom Navigation Bar
import 'package:pj1/account.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart'; // HomePage
import 'package:pj1/target.dart';

// ต้อง import MainHomeScreen เพื่อเข้าถึง Category class ที่เราสร้างไว้
import 'package:pj1/add.dart' as MainScreen; // ตั้ง alias ให้ไม่ชนกัน

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({Key? key}) : super(key: key);

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  File? selectedImage; // สำหรับเก็บรูปภาพที่เลือก
  final ImagePicker _picker = ImagePicker(); // Instance ของ ImagePicker
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool isLoading = false;
  final TextEditingController activityNameController =
      TextEditingController(); // สำหรับชื่อกิจกรรม

  List<MainScreen.Category> _categories =
      []; // ลิสต์ของหมวดหมู่ทั้งหมด (default + user custom)
  int? _selectedCategoryId; // หมวดหมู่ที่ถูกเลือกใน Dropdown

  int _selectedIndex = 0; // สำหรับ Bottom Navigation Bar

  // --- ฟังก์ชันสำหรับการเลือกรูปภาพ ---
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- ฟังก์ชันสำหรับโหลดหมวดหมู่ที่มีอยู่จาก Firebase และ Default ---
  Future<void> _loadCategories() async {
    try {
      final response = await http.get(Uri.parse(
          '${ApiEndpoints.baseUrl}/api/category/getCategory?uid=${FirebaseAuth.instance.currentUser?.uid}'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<MainScreen.Category> loadedCategories = data.map((item) {
          return MainScreen.Category(
            id: item['cate_id'],
            iconPath: '',
            label: item['cate_name'],
          );
        }).toList();

        setState(() {
          _categories = loadedCategories;

          // ตรวจสอบให้แน่ใจว่า _selectedCategoryId เป็นค่าที่ถูกต้อง
          if (_categories.isNotEmpty) {
            // ถ้า _selectedCategoryId ไม่มีค่า หรือ ค่าที่เลือกไม่มีอยู่ในลิสต์ที่โหลดมา
            if (_selectedCategoryId == null ||
                !_categories.any((c) => c.id == _selectedCategoryId)) {
              _selectedCategoryId =
                  _categories.first.id; // ให้เลือกตัวแรกเป็นค่าเริ่มต้น
            }
          } else {
            _selectedCategoryId =
                null; // ถ้าไม่มีหมวดหมู่เลย ก็ไม่มีค่าที่เลือก
          }
        });
      } else {
        print('Failed to load categories: ${response.statusCode}');
        setState(() {
          _categories = [];
          _selectedCategoryId =
              null; // ตั้งค่าให้เป็น null เมื่อโหลดข้อมูลไม่สำเร็จ
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _categories = [];
        _selectedCategoryId = null; // ตั้งค่าให้เป็น null เมื่อเกิดข้อผิดพลาด
      });
    }
  }

  Future<String?> _uploadActivityImage(String userId, File imageFile) async {
    try {
      final random = Random();
      final randomNumber =
          random.nextInt(90000) + 10000; // เลข 5 หลัก 10000-99999

      final ref = _storage
          .ref()
          .child('activity_pics')
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

  // --- ฟังก์ชันสำหรับเพิ่มกิจกรรมใหม่ลง Firebase ---
  Future<void> _createActivity() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String activityName = activityNameController.text.trim();
    print(activityName);
    // ✅ เพิ่มการตรวจสอบ category ที่เลือก
    if (activityName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาใส่ชื่อกิจกรรม')),
      );
      return;
    }

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพ')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกหมวดหมู่')),
      );
      return;
    }

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบ')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final imageUrl = await _uploadActivityImage(uid, selectedImage!);
      print('Image URL: $imageUrl');
      print(uid);
      print(_selectedCategoryId);
      print(activityName);

      if (imageUrl != null) {
        final response = await http.post(
          Uri.parse('${ApiEndpoints.baseUrl}/api/activity/createAct'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid': uid,
            'cate_id': _selectedCategoryId,
            'act_name': activityName,
            'act_pic': imageUrl,
          }),
        );

        if (response.statusCode == 200) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เพิ่มกิจกรรมสำเร็จ')),
            );
            Navigator.pop(context, true);
          }
        } else {
          final message =
              jsonDecode(response.body)['message'] ?? 'บันทึกกิจกรรมล้มเหลว';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e) {
      print('Error creating activity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- ฟังก์ชันสำหรับ Bottom Navigation Bar ---
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Targetpage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Graphpage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AccountPage()),
        );
        break;
    }
  }

  // --- Life Cycle Methods ---
  @override
  void initState() {
    super.initState();
    _loadCategories(); // โหลดหมวดหมู่เมื่อ Widget ถูกสร้างขึ้น
  }

  @override
  void dispose() {
    activityNameController.dispose();
    super.dispose();
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Column(
                  children: [
                    Container(
                      color: const Color(0xFF564843),
                      height: MediaQuery.of(context).padding.top + 80,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
                // โลโก้
                Positioned(
                  top: MediaQuery.of(context).padding.top + 30,
                  left: MediaQuery.of(context).size.width / 2 - 50,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // ปุ่มย้อนกลับ
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // กลับไปหน้าก่อนหน้า
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ย้อนกลับ',
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // กล่องกรอกข้อมูล
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6D2CD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/magic-wand.png',
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Create Activity',
                        style: GoogleFonts.kanit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5B4436),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ปุ่มเลือกรูปภาพ
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEAE3),
                        shape: BoxShape.circle,
                      ),
                      child: selectedImage == null
                          ? const Icon(Icons.add_photo_alternate,
                              size: 40, color: Colors.white)
                          : ClipOval(
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'เพิ่มรูปภาพ',
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      color: const Color(0xFF564843),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dropdown สำหรับเลือก Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC98993),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        // ✅ แก้ไขตรงนี้ - ตรวจสอบว่า categories ไม่ว่างและ selectedCategoryId ตรงกับ items
                        value: _categories.isNotEmpty &&
                                _selectedCategoryId != null &&
                                _categories
                                    .any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null,
                        isExpanded: true,
                        dropdownColor: const Color(0xFFC98993),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white),
                        style: GoogleFonts.kanit(
                            color: Colors.white, fontSize: 16),
                        hint: Text(
                          'เลือกหมวดหมู่...',
                          style: GoogleFonts.kanit(color: Colors.white70),
                        ),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedCategoryId = newValue;
                          });
                        },
                        items: _categories.map<DropdownMenuItem<int>>(
                            (MainScreen.Category category) {
                          return DropdownMenuItem<int>(
                            value: category.id,
                            child: Text(category.label),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ช่องกรอกชื่อกิจกรรม
                  TextFormField(
                    controller: activityNameController,
                    decoration: InputDecoration(
                      hintText: 'Activity Name......',
                      hintStyle: GoogleFonts.kanit(color: Colors.white),
                      filled: true,
                      fillColor: const Color(0xFF564843),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: GoogleFonts.kanit(color: Colors.white),
                  ),
                  const SizedBox(height: 30),

                  // ปุ่ม Complete
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _createActivity, // เรียกใช้ฟังก์ชันเพิ่มกิจกรรมเมื่อกด
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF564843),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'Complete',
                        style: GoogleFonts.kanit(
                            color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // Bottom Navigation Bar (เหมือนเดิม)
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFE6D2CD),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        selectedFontSize: 17,
        unselectedFontSize: 17,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/add.png', width: 24, height: 24),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/wishlist-heart.png',
                width: 24, height: 24),
            label: 'Target',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/stats.png', width: 24, height: 24),
            label: 'Graph',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/accout.png', width: 24, height: 24),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
