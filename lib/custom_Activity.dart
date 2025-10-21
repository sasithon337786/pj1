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
import 'package:flutter/services.dart'; // ✨ สำหรับ LengthLimitingTextInputFormatter / MaxLengthEnforcement
import 'package:characters/characters.dart'; // ✨ สำหรับนับตัวอักษรจริง (รวมอีโมจิ/ตัวผสม)
import 'package:pj1/services/auth_service.dart';

// ต้อง import ไฟล์ที่เกี่ยวข้องทั้งหมดที่ใช้ใน Bottom Navigation Bar
import 'package:pj1/account.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart'; // HomePage
import 'package:pj1/target.dart';

// ต้อง import MainHomeScreen เพื่อเข้าถึง Category class ที่เราสร้างไว้
import 'package:pj1/add.dart' as MainScreen;
import 'package:pj1/widgets/error_notifier.dart'; // ตั้ง alias ให้ไม่ชนกัน

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
        print('Failed to get user role: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in');
        return;
      }

      // ดึง Firebase ID Token
      final idToken = await user.getIdToken();

      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/category/getCategory?uid=${user.uid}',
      );

      // ส่ง token ใน header
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

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

          if (_categories.isNotEmpty) {
            if (_selectedCategoryId == null ||
                !_categories.any((c) => c.id == _selectedCategoryId)) {
              _selectedCategoryId = _categories.first.id;
            }
          } else {
            _selectedCategoryId = null;
          }
        });
      } else {
        print('Failed to load categories: ${response.statusCode}');
        setState(() {
          _categories = [];
          _selectedCategoryId = null;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _categories = [];
        _selectedCategoryId = null;
      });
    }
  }

// --------------------------
// 1) อัปโหลดรูป activity
// --------------------------
  Future<String?> _uploadActivityImage(String userId, File imageFile) async {
    try {
      final random = Random();
      final randomNumber = random.nextInt(90000) + 10000;
      final fileName = '${userId}_$randomNumber.jpg';

      // ✅ บังคับ bucket + path ให้ตรงเป๊ะด้วย gs://
      final ref = FirebaseStorage.instance.refFromURL(
        'gs://finalproject-609a4.firebasestorage.app/activity_pics/$fileName',
      );

      final snapshot = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      if (snapshot.state != TaskState.success) {
        debugPrint('❌ Upload failed: state=${snapshot.state}');
        return null;
      }
      await ref.getMetadata();
      final url = await ref.getDownloadURL();
      debugPrint('✅ Uploaded OK -> bucket=${ref.bucket}, path=${ref.fullPath}');
      debugPrint('✅ URL: $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint('🔥 FirebaseException [${e.code}] ${e.message}');
      return null;
    } catch (e) {
      debugPrint('🔥 Error uploading activity image: $e');
      return null;
    }
  }

// --------------------------
// 2) Create Activity
// --------------------------
  Future _createActivity() async {
    final user = FirebaseAuth.instance.currentUser;

    // ✨ ตรวจความถูกต้องของ input
    final rawName = activityNameController.text.trim();
    final nameLength = rawName.characters.length;

    if (rawName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาใส่ชื่อกิจกรรม')));
      return;
    }
    if (nameLength > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ชื่อกิจกรรมห้ามเกิน 30 ตัวอักษร')));
      return;
    }
    if (selectedImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเลือกรูปภาพ')));
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเลือกหมวดหมู่')));
      return;
    }
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบ')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw Exception('ไม่สามารถดึง ID Token ได้');
      }

      // 🧩 ดึง role จาก authService
      final role =
          await AuthService().getUserRole(); // <- ดึงจาก service ของคุณ
      final isAdmin = role?.toLowerCase() == 'admin';

      // อัปโหลดรูปภาพ
      final imageUrl = await _uploadActivityImage(user.uid, selectedImage!);
      if (imageUrl == null) throw Exception('อัปโหลดรูปภาพไม่สำเร็จ');

      // ✅ เลือก endpoint ตาม role
      final endpoint =
          isAdmin ? '/api/activity/createActAdmin' : '/api/activity/createAct';

      final postUrl = '${ApiEndpoints.baseUrl}$endpoint';
      final cateId = (_selectedCategoryId is int)
          ? _selectedCategoryId as int
          : int.tryParse(_selectedCategoryId.toString());

      if (cateId == null) throw Exception('รหัสหมวดหมู่ไม่ถูกต้อง');

      final bodyData = {
        'cate_id': cateId,
        'act_name': rawName,
        'act_pic': imageUrl,
      };

      final response = await http.post(
        Uri.parse(postUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มกิจกรรมสำเร็จ')),
        );
        Navigator.pop(context, true);
      } else {
        // ดึงข้อความจาก backend เช่น "กิจกรรมซ้ำ"
        String message = 'บันทึกกิจกรรมล้มเหลว';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] is String)
            message = data['message'];
        } catch (_) {}
        if (mounted) ErrorNotifier.showSnack(context, message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    activityNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC98993),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
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
                      TextFormField(
                        controller: activityNameController,
                        // ✨ จำกัดความยาว 30 ตัวอักษรตั้งแต่ UI
                        maxLength: 20,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(30),
                        ],
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
                          counterText: '', // ไม่แสดงตัวนับใต้ช่อง
                        ),
                        style: GoogleFonts.kanit(color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _createActivity,
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
          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
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
