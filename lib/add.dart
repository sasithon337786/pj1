import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ต้อง import ไฟล์ที่เกี่ยวข้องทั้งหมด
import 'package:pj1/account.dart';
import 'package:pj1/chooseactivity.dart'; // ยังไม่ได้ใช้โดยตรงใน MainHomeScreen แต่เผื่อไว้
import 'package:pj1/custom_Activity.dart'; // CreateActivityScreen ที่เราปรับปรุง
import 'package:pj1/dialog_coagy.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart'; // HomePage
import 'package:pj1/target.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

// --- Class สำหรับ Category (เหมือนเดิม) ---
class Category {
  final String iconPath;
  final String label;
  final bool isNetworkImage;

  Category(
      {required this.iconPath,
      required this.label,
      this.isNetworkImage = false});
}

// --- Class สำหรับ Task (กิจกรรม) ---
// *** เพิ่ม isNetworkImage เข้ามาใน Task Class ด้วยนะจ๊ะ ***
class Task {
  final String iconPath;
  final String label;
  final bool isNetworkImage; // เพิ่ม property นี้

  Task(
      {required this.iconPath,
      required this.label,
      this.isNetworkImage = false});
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  // --- ตัวแปรและข้อมูลเริ่มต้น ---
  List<Category> categories =
      []; // ลิสต์ของหมวดหมู่ทั้งหมด (default + user custom)

  // หมวดหมู่เริ่มต้น (จาก Asset)
  final List<Category> _defaultCategories = [
    Category(iconPath: 'assets/icons/heart-health-muscle.png', label: 'Health'),
    Category(iconPath: 'assets/icons/gym.png', label: 'Sports'),
    Category(iconPath: 'assets/icons/life.png', label: 'Lifestyle'),
    Category(iconPath: 'assets/icons/pending.png', label: 'Time'),
  ];

  // กิจกรรมเริ่มต้น (จาก Asset) ที่ผูกกับหมวดหมู่
  Map<String, List<Task>> _defaultTasksByCategory = {
    'Health': [
      Task(iconPath: 'assets/images/raindrops.png', label: 'Drink Water'),
      Task(iconPath: 'assets/images/eat.png', label: 'Eat'),
      Task(iconPath: 'assets/images/meditation.png', label: 'Meditation'),
      Task(iconPath: 'assets/images/yoga.png', label: 'Yoga'),
    ],
    'Sports': [
      Task(iconPath: 'assets/images/cycling.png', label: 'Cycling'),
      Task(iconPath: 'assets/images/run.png', label: 'Running'),
      Task(iconPath: 'assets/images/workout-machine.png', label: 'Exercise'),
      Task(iconPath: 'assets/images/walking.png', label: 'walk'),
    ],
    'Lifestyle': [
      Task(iconPath: 'assets/images/stack-of-books.png', label: 'Read a book'),
      Task(iconPath: 'assets/images/sleeping.png', label: 'Sleep early'),
      Task(iconPath: 'assets/images/peace-of-mind.png', label: 'Mind clearing'),
      Task(iconPath: 'assets/images/education.png', label: 'Learning'),
    ],
    'Time': [
      Task(iconPath: 'assets/images/sheet-mask.png', label: 'Facial mask'),
      Task(iconPath: 'assets/images/skincare-routine.png', label: 'Routine'),
      Task(iconPath: 'assets/images/hair-dryer.png', label: 'Hair routine'),
      Task(iconPath: 'assets/images/popcorn.png', label: 'Free Time'),
    ],
  };

  List<Task> _displayedTasks = []; // ลิสต์ของกิจกรรมที่จะแสดงผลในปัจจุบัน
  int _selectedIndex = 0; // สำหรับ Bottom Navigation Bar
  TextEditingController categoryController =
      TextEditingController(); // สำหรับเพิ่มหมวดหมู่

  String selectedCategoryLabel = 'Health'; // หมวดหมู่ที่ถูกเลือกอยู่ในปัจจุบัน

  StreamSubscription<User?>?
      _authStateChangesSubscription; // สำหรับฟังสถานะ Login

  // --- ฟังก์ชันสำหรับการโหลดข้อมูลและนำทาง ---

  // ฟังก์ชันสำหรับ Bottom Navigation Bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          // ใช้ Replacement เพื่อไม่ให้ย้อนกลับมาหน้านี้ได้ง่ายๆ
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

  // ฟังก์ชันเพิ่มหมวดหมู่ (เหมือนเดิม)
  Future<void> addCustomCategory(File imageFile, String label) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('คุณต้องเข้าสู่ระบบก่อนจึงจะเพิ่มหมวดหมู่ได้'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('กำลังเพิ่มหมวดหมู่...'),
          duration: Duration(seconds: 2)),
    );

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('category_images')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('categories').add({
        'userId': user.uid,
        'label': label,
        'iconPath': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await loadUserCategories(); // โหลดหมวดหมู่ใหม่ทั้งหมด
      setState(() {
        selectedCategoryLabel = label; // เลือกหมวดหมู่ที่เพิ่งเพิ่มทันที
      });
      await _loadTasksForSelectedCategory(); // โหลดกิจกรรมของหมวดหมู่ที่เลือกใหม่

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('เพิ่มหมวดหมู่สำเร็จ!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      print('Error adding category to Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เพิ่มหมวดหมู่ไม่สำเร็จ: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // ฟังก์ชันโหลดหมวดหมู่ของผู้ใช้ (ปรับให้เรียกว่า _loadTasksForSelectedCategory ด้วย)
  Future<void> loadUserCategories() async {
    final user = FirebaseAuth.instance.currentUser;

    List<Category> currentCategories =
        List.from(_defaultCategories); // เริ่มต้นด้วยหมวดหมู่พื้นฐานเสมอ

    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('categories')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: false)
            .get();

        List<Category> userCustomCategories = snapshot.docs.map((doc) {
          return Category(
            iconPath: doc['iconPath'],
            label: doc['label'],
            isNetworkImage: true,
          );
        }).toList();
        currentCategories.addAll(userCustomCategories);
      } catch (e) {
        print('Error loading user categories: $e');
      }
    }

    setState(() {
      categories = currentCategories;
      // ตรวจสอบว่าหมวดหมู่ที่เลือกไว้ยังอยู่ในลิสต์หรือไม่ ถ้าไม่ให้เลือกอันแรกสุด
      if (!categories.any((cat) => cat.label == selectedCategoryLabel)) {
        if (categories.isNotEmpty) {
          selectedCategoryLabel = categories.first.label;
        } else {
          selectedCategoryLabel = 'Health'; // Fallback
        }
      }
    });
    // โหลดกิจกรรมสำหรับหมวดหมู่ที่ถูกเลือกหลังจากโหลดหมวดหมู่เสร็จ
    _loadTasksForSelectedCategory();
  }

  // *** ฟังก์ชันใหม่: โหลดกิจกรรมตามหมวดหมู่ที่เลือกและตามผู้ใช้ ***
  Future<void> _loadTasksForSelectedCategory() async {
    final user = FirebaseAuth.instance.currentUser;
    List<Task> tasksToDisplay = [];

    // เพิ่มกิจกรรมเริ่มต้นสำหรับหมวดหมู่ที่เลือก (ถ้ามี)
    if (_defaultTasksByCategory.containsKey(selectedCategoryLabel)) {
      tasksToDisplay.addAll(_defaultTasksByCategory[selectedCategoryLabel]!);
    }

    // โหลดกิจกรรมที่ผู้ใช้สร้างเองสำหรับหมวดหมู่ที่เลือกจาก Firebase
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('activities')
            .where('userId', isEqualTo: user.uid)
            .where('categoryLabel', isEqualTo: selectedCategoryLabel)
            .orderBy('timestamp', descending: false)
            .get();

        List<Task> userCustomTasks = snapshot.docs.map((doc) {
          return Task(
            iconPath: doc['iconPath'],
            label: doc['label'],
            isNetworkImage:
                true, // กิจกรรมที่โหลดจาก Firebase เป็น Network Image เสมอ
          );
        }).toList();
        tasksToDisplay.addAll(userCustomTasks);
      } catch (e) {
        print(
            'Error loading user activities for category $selectedCategoryLabel: $e');
        // ไม่ต้องแสดง SnackBar ถ้า error เพราะอาจจะเกิดจากการไม่มีข้อมูล
      }
    }

    setState(() {
      _displayedTasks = tasksToDisplay;
    });
  }

  // ฟังก์ชันนำทางไปหน้า CreateActivityScreen
  void _navigateToCreateActivityScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateActivityScreen(),
      ),
    );
    // เมื่อกลับมาจาก CreateActivityScreen ให้โหลดหมวดหมู่และกิจกรรมใหม่
    // เพราะอาจจะมีการเพิ่มหมวดหมู่ใหม่ หรือเพิ่มกิจกรรมในหมวดหมู่ที่มีอยู่
    loadUserCategories();
    // _loadTasksForSelectedCategory(); // loadUserCategories() จะเรียกตัวนี้อยู่แล้ว
  }

  // --- Life Cycle Methods ---
  @override
  void initState() {
    super.initState();
    // ฟังการเปลี่ยนแปลงสถานะผู้ใช้
    _authStateChangesSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      loadUserCategories(); // โหลดหมวดหมู่และกิจกรรมใหม่ทุกครั้งที่สถานะผู้ใช้เปลี่ยน
    });
    // เรียกโหลดหมวดหมู่และกิจกรรมครั้งแรกเมื่อ Widget ถูกสร้างขึ้น
    loadUserCategories();
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    categoryController.dispose();
    super.dispose();
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          Column(
            children: [
              // ส่วนหัวของหน้าจอ
              Container(
                color: const Color(0xFF564843),
                height: MediaQuery.of(context).padding.top + 80,
                width: double.infinity,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ปุ่มเพิ่มหมวดหมู่
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF564843),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                            onPressed: () {
                              categoryController.clear();
                              showAddCategoryDialog(
                                context,
                                categoryController,
                                (File image, String name) async {
                                  await addCustomCategory(image, name);
                                },
                              );
                            },
                            child: Text(
                              'เพิ่มหมวดหมู่',
                              style: GoogleFonts.kanit(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // แถวไอคอนหมวดหมู่ (ใช้ Wrap เพื่อการจัดวางและช่องไฟ)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 16.0, // ระยะห่างแนวนอน
                          runSpacing: 16.0, // ระยะห่างแนวตั้ง
                          alignment: WrapAlignment.center, // จัดให้อยู่กึ่งกลาง
                          children: categories.map((category) {
                            bool isSelected =
                                category.label == selectedCategoryLabel;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategoryLabel = category.label;
                                  _loadTasksForSelectedCategory(); // <<< โหลดกิจกรรมใหม่เมื่อเลือกหมวดหมู่
                                });
                              },
                              child: CategoryIcon(
                                icon: category.iconPath,
                                label: category.label,
                                isSelected: isSelected,
                                isNetworkImage: category.isNetworkImage,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // รายการกิจกรรม
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: _displayedTasks.map((task) {
                          // <<< ใช้ _displayedTasks ที่โหลดมา
                          return TaskCard(
                            iconPath: task.iconPath,
                            label: task.label,
                            isNetworkImage: task
                                .isNetworkImage, // <<< ส่งค่า isNetworkImage ไปให้ TaskCard
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),

                      // ปุ่ม Custom (เพิ่มกิจกรรม)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5E4A47),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            _navigateToCreateActivityScreen(); // เรียกใช้ฟังก์ชันนำทาง
                          },
                          child: const Text(
                            'Custom',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Logo และปุ่มย้อนกลับ (เหมือนเดิม)
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

// --- CategoryIcon Widget (เหมือนเดิมตามที่หนูให้มา) ---
class CategoryIcon extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final bool isNetworkImage;

  const CategoryIcon({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isNetworkImage = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (isNetworkImage) {
      imageWidget = Image.network(
        icon,
        width: 24,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, size: 24, color: Colors.red);
        },
      );
    } else {
      imageWidget = Image.asset(
        icon,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        color: isSelected ? Colors.black : null,
      );
    }

    return Column(
      children: [
        CircleAvatar(
          backgroundColor: isSelected ? Colors.white : const Color(0xFFE6D2C0),
          radius: 24,
          child: ClipOval(
            child: imageWidget,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.kanit(
            fontSize: 12,
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// --- TaskCard Widget ---
// *** มีการแก้ไขให้รับ isNetworkImage และแสดงผลรูปจาก Network/Asset ได้ถูกต้อง ***
class TaskCard extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isNetworkImage; // <<< เพิ่ม property นี้

  const TaskCard({
    super.key,
    required this.iconPath,
    required this.label,
    this.isNetworkImage = false, // <<< กำหนดค่าเริ่มต้น
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (isNetworkImage) {
      imageWidget = Image.network(
        iconPath,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, size: 48, color: Colors.red);
        },
      );
    } else {
      // ตรวจสอบว่าเป็น assets/ หรือไม่ เพราะบางทีอาจจะเก็บเป็น File path ในอนาคต (ถ้ามาจาก gallery โดยตรง)
      // แต่ในกรณีนี้เราจะอัปโหลดขึ้น Firebase เสมอ ถ้า isNetworkImage เป็น false แสดงว่าเป็น Asset แน่นอน
      imageWidget = Image.asset(
        iconPath,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
      );
    }

    return Card(
      color: const Color(0xFFF3E1E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            imageWidget, // ใช้ Widget ที่สร้างตามเงื่อนไข
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.kanit(
                  fontSize: 20, color: const Color(0xFFC98993)),
            ),
          ],
        ),
        trailing: const Icon(Icons.add, color: Color(0xFFC98993)),
        onTap: () {
          // ตรงนี้คือการกดกิจกรรมแต่ละอัน สามารถเพิ่ม logic ไปยังหน้าทำกิจกรรมได้
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('คุณเลือกกิจกรรม: $label')),
          );
        },
      ),
    );
  }
}
