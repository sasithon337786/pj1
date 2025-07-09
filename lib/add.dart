import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ต้อง import ไฟล์ที่เกี่ยวข้องทั้งหมด
import 'package:pj1/account.dart';
import 'package:pj1/chooseactivity.dart'; // ยังไม่ได้ใช้โดยตรงใน MainHomeScreen แต่เผื่อไว้
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/custom_Activity.dart'; // CreateActivityScreen ที่เราปรับปรุง
import 'package:pj1/dialog_coagy.dart';
import 'package:pj1/doing_activity.dart';
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
  final int? id;
  final String iconPath;
  final String label;
  final bool isNetworkImage;

  Category(
      {this.id,
      required this.iconPath,
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
  int? selectedCategoryId;
  // หมวดหมู่เริ่มต้น (จาก Asset)
  final List<Category> _defaultCategories = [
    Category(iconPath: 'assets/icons/heart-health-muscle.png', label: 'Health'),
    Category(iconPath: 'assets/icons/gym.png', label: 'Sports'),
    Category(iconPath: 'assets/icons/life.png', label: 'Lifestyle'),
    Category(iconPath: 'assets/icons/pending.png', label: 'Time'),
    //cate_id = default
    //cate_pic=iconPath
    //cate_name=label
    //uid = default
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
      //act_id = default
      //act_pic=iconPath
      //act_name=label
      //uid = default
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
  Future<void> loadUserCategories() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  List<Category> currentCategories = List.from(_defaultCategories);

  if (uid != null) {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/category/getCategory?uid=$uid'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categoriesData = (data as List).map((item) {
          return Category(
            id: int.tryParse(item['cate_id'].toString()), // แปลงเป็น int
            iconPath: item['cate_pic'],
            label: item['cate_name'],
            isNetworkImage: true,
          );
        }).toList();

        currentCategories.addAll(categoriesData);
      } else {
        print('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  setState(() {
    categories = currentCategories;
    if (categories.isNotEmpty) {
      selectedCategoryLabel = categories[0].label;
      selectedCategoryId = categories[0].id;  // กำหนด id ของหมวดแรกด้วย
      _loadTasksForSelectedCategory();
    }
  });
}

  // *** ฟังก์ชันใหม่: โหลดกิจกรรมตามหมวดหมู่ที่เลือกและตามผู้ใช้ ***
  Future<void> _loadTasksForSelectedCategory() async {
    final user = FirebaseAuth.instance.currentUser;
    List<Task> tasksToDisplay = [];

    // 1. กิจกรรม default จาก Asset ตาม label
    if (_defaultTasksByCategory.containsKey(selectedCategoryLabel)) {
      tasksToDisplay.addAll(_defaultTasksByCategory[selectedCategoryLabel]!);
    }

    // 2. กิจกรรมจากฐานข้อมูล ที่ user สร้าง (ส่ง cate_id ไปด้วย)
    if (user != null && selectedCategoryId != null) {
      try {
        final response = await http.get(
          Uri.parse(
            '${ApiEndpoints.baseUrl}/api/activity/getAct?uid=${user.uid}&cate_id=$selectedCategoryId',
          ),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userCustomTasks = (data as List)
              .map((item) => Task(
                    iconPath: item['act_pic'],
                    label: item['act_name'],
                    isNetworkImage: true,
                  ))
              .toList();

          tasksToDisplay.addAll(userCustomTasks);
        } else {
          print('Failed to load user tasks: ${response.statusCode}');
        }
      } catch (e) {
        print('Error loading tasks for categoryId $selectedCategoryId: $e');
      }
    }

    // 3. อัปเดต state
    setState(() {
      _displayedTasks = tasksToDisplay;
    });
  }

  Future<List<Task>> getTasksFromDatabase(String uid) async {
    // final uid = FirebaseAuth.instance.currentUser!.uid;
    print(uid);
    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/api/activity/getAct?uid=${uid}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((item) => Task(
                label: item['act_name'] ?? '', // ✅ ชื่อกิจกรรม
                iconPath: item['act_pic'] ?? '',
                isNetworkImage: true,
              ))
          .toList();
    } else {
      throw Exception(
          'Failed to load activity with status: ${response.statusCode}');
    }
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
                            onPressed: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (context) => const AddCategoryDialog(),
                              );

                              if (result == true) {
                                loadUserCategories();
                              }
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
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal, // เลื่อนแนวนอน
                          child: Row(
                            children: categories.map((category) {
                              bool isSelected =
                                  category.label == selectedCategoryLabel;
                              return Padding(
                                padding: const EdgeInsets.only(
                                    right: 16), // เว้นระยะห่างระหว่างไอคอน
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCategoryLabel = category.label;
                                      selectedCategoryId = category
                                          .id; // <-- เก็บ cate_id ที่เลือก
                                      _loadTasksForSelectedCategory(); // โหลดกิจกรรมใหม่ตามหมวดหมู่ใหม่
                                    });
                                  },
                                  child: CategoryIcon(
                                    icon: category.iconPath,
                                    label: category.label,
                                    isSelected: isSelected,
                                    isNetworkImage: category.isNetworkImage,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
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

                      // FutureBuilder<List<Task>>(
                      //   future: getTasksFromDatabase(
                      //       FirebaseAuth.instance.currentUser!.uid),
                      //   builder: (context, snapshot) {
                      //     if (snapshot.connectionState ==
                      //         ConnectionState.waiting) {
                      //       return const Center(
                      //           child: CircularProgressIndicator());
                      //     } else if (snapshot.hasError) {
                      //       return Center(
                      //           child:
                      //               Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                      //     } else if (!snapshot.hasData ||
                      //         snapshot.data!.isEmpty) {
                      //       return const Center(child: Text('ไม่มีข้อมูล'));
                      //     }

                      //     final tasks = snapshot.data!;

                      //     return ListView(
                      //       shrinkWrap: true,
                      //       physics: const NeverScrollableScrollPhysics(),
                      //       padding: const EdgeInsets.symmetric(horizontal: 16),
                      //       children: tasks.map((task) {
                      //         return TaskCard(
                      //           iconPath: task.iconPath,
                      //           label: task.label,
                      //           isNetworkImage: task.isNetworkImage,
                      //         );
                      //       }).toList(),
                      //     );
                      //   },
                      // ),

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
  final Function()? onEdit;
  final Function()? onDelete;

  const CategoryIcon({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isNetworkImage = false,
    this.onEdit,
    this.onDelete,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor:
                  isSelected ? Colors.white : const Color(0xFFE6D2C0),
              radius: 24,
              child: ClipOval(child: imageWidget),
            ),
            if (isNetworkImage) // ถ้าเป็น custom category ให้แสดงปุ่ม 3 จุด
              PopupMenuButton<String>(
                icon:
                    const Icon(Icons.more_vert, color: Colors.white, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('แก้ไข'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('ลบ'),
                  ),
                ],
              ),
          ],
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
            imageWidget,
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.kanit(
                  fontSize: 20, color: const Color(0xFFC98993)),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(  
          icon: const Icon(Icons.more_vert, color: Color(0xFFC98993)),
          onSelected: (value) {
            if (value == 'edit') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('แก้ไขกิจกรรม: $label')),
              );
              // 👉 หรือจะเปิดหน้าแก้ไขหรือ dialog ก็ได้
            } else if (value == 'delete') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ลบกิจกรรม: $label')),
              );
              // 👉 หรือจะลบจาก Firestore ตรงนี้
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFFC98993)),
                  const SizedBox(width: 8),
                  Text('แก้ไข', style: GoogleFonts.kanit()),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Color(0xFFC98993)),
                  const SizedBox(width: 8),
                  Text('ลบ', style: GoogleFonts.kanit()),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChooseactivityPage(
                  // activityName: label,
                  // iconPath: iconPath,
                  // isNetworkImage: isNetworkImage,
                  ),
            ),
          );
        },
      ),
    );
  }
}
