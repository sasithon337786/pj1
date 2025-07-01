import 'dart:async';
import 'dart:io'; // สำหรับ File
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับ FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Cloud Firestore
import 'package:firebase_storage/firebase_storage.dart'; // สำหรับ Firebase Storage
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // สำหรับ ImagePicker

// ต้อง import ไฟล์ที่เกี่ยวข้องทั้งหมดที่ใช้ใน Bottom Navigation Bar
import 'package:pj1/account.dart';
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
  File? _image; // สำหรับเก็บรูปภาพที่เลือก
  final ImagePicker _picker = ImagePicker(); // Instance ของ ImagePicker

  final TextEditingController activityNameController =
      TextEditingController(); // สำหรับชื่อกิจกรรม

  List<MainScreen.Category> _categories =
      []; // ลิสต์ของหมวดหมู่ทั้งหมด (default + user custom)
  String? _selectedCategoryLabel; // หมวดหมู่ที่ถูกเลือกใน Dropdown

  int _selectedIndex = 0; // สำหรับ Bottom Navigation Bar

  // --- ฟังก์ชันสำหรับการเลือกรูปภาพ ---
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // --- ฟังก์ชันสำหรับโหลดหมวดหมู่ที่มีอยู่จาก Firebase และ Default ---
  Future<void> _loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    List<MainScreen.Category> currentCategories = [
      // หมวดหมู่เริ่มต้น (จาก Asset)
      MainScreen.Category(
          iconPath: 'assets/icons/heart-health-muscle.png', label: 'Health'),
      MainScreen.Category(iconPath: 'assets/icons/gym.png', label: 'Sports'),
      MainScreen.Category(
          iconPath: 'assets/icons/life.png', label: 'Lifestyle'),
      MainScreen.Category(iconPath: 'assets/icons/pending.png', label: 'Time'),
    ];

    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('categories')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: false)
            .get();

        List<MainScreen.Category> userCustomCategories =
            snapshot.docs.map((doc) {
          return MainScreen.Category(
            iconPath: doc['iconPath'],
            label: doc['label'],
            isNetworkImage: true,
          );
        }).toList();
        currentCategories.addAll(userCustomCategories);
      } catch (e) {
        print('Error loading categories for activity screen: $e');
        // ไม่ต้องแสดง SnackBar เพราะอาจจะเกิดจากการที่ผู้ใช้ยังไม่มีหมวดหมู่ custom
      }
    }

    setState(() {
      _categories = currentCategories;
      // กำหนดค่าเริ่มต้นของ Dropdown เป็นหมวดหมู่แรกสุด หากยังไม่มีการเลือก
      if (_selectedCategoryLabel == null && _categories.isNotEmpty) {
        _selectedCategoryLabel = _categories.first.label;
      }
    });
  }

  // --- ฟังก์ชันสำหรับเพิ่มกิจกรรมใหม่ลง Firebase ---
  Future<void> _addActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('คุณต้องเข้าสู่ระบบก่อนจึงจะเพิ่มกิจกรรมได้'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // ตรวจสอบข้อมูลที่จำเป็น
    if (_image == null ||
        activityNameController.text.trim().isEmpty ||
        _selectedCategoryLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('กรุณาเลือกรูปภาพ, ใส่ชื่อกิจกรรม และเลือกหมวดหมู่'),
            backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('กำลังเพิ่มกิจกรรม...'),
          duration: Duration(seconds: 2)),
    );

    try {
      // 1. อัปโหลดรูปภาพไป Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('activity_images') // เก็บรูปกิจกรรมในโฟลเดอร์นี้
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(_image!);
      final imageUrl = await ref.getDownloadURL();

      // 2. บันทึกข้อมูลกิจกรรมไป Firebase Firestore
      await FirebaseFirestore.instance.collection('activities').add({
        'userId': user.uid, // UID ของผู้ใช้ที่สร้าง
        'categoryLabel': _selectedCategoryLabel, // หมวดหมู่ที่กิจกรรมนี้จะอยู่
        'label': activityNameController.text.trim(), // ชื่อกิจกรรม
        'iconPath': imageUrl, // URL รูปภาพ
        'timestamp': FieldValue.serverTimestamp(), // เวลาที่สร้าง
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('เพิ่มกิจกรรมสำเร็จ!'),
            backgroundColor: Colors.green),
      );

      // กลับไปหน้า MainHomeScreen (ซึ่งจะโหลดข้อมูลใหม่เอง)
      Navigator.pop(context);
    } catch (e) {
      print('Error adding activity to Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เพิ่มกิจกรรมไม่สำเร็จ: $e'),
            backgroundColor: Colors.red),
      );
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
                      child: _image == null
                          ? const Icon(Icons.add_photo_alternate,
                              size: 40, color: Colors.white)
                          : ClipOval(
                              child: Image.file(
                                _image!,
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
                      child: DropdownButton<String>(
                        value: _selectedCategoryLabel,
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
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategoryLabel = newValue;
                          });
                        },
                        items: _categories.map<DropdownMenuItem<String>>(
                            (MainScreen.Category category) {
                          return DropdownMenuItem<String>(
                            value: category.label,
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
                          _addActivity, // เรียกใช้ฟังก์ชันเพิ่มกิจกรรมเมื่อกด
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
