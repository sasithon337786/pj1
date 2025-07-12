import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/chooseactivity.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/custom_Activity.dart';
import 'package:pj1/manage_categories_dialog.dart';
import 'package:pj1/edit_activity.dart';

class MainHomeAdminScreen extends StatefulWidget {
  const MainHomeAdminScreen({super.key});

  @override
  State<MainHomeAdminScreen> createState() => _MainHomeAdminScreenState();
}

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


class Task {
  final String iconPath;
  final String label;
  final bool isNetworkImage;
  final int? act_id;

  Task({
    required this.iconPath,
    required this.label,
    this.isNetworkImage = false,
    this.act_id,
  });
}

class _MainHomeAdminScreenState extends State<MainHomeAdminScreen> {
  List<Category> categories = [];
  int? selectedCategoryId;
  final List<Category> _defaultCategories = [
    Category(iconPath: 'assets/icons/heart-health-muscle.png', label: 'Health'),
    Category(iconPath: 'assets/icons/gym.png', label: 'Sports'),
    Category(iconPath: 'assets/icons/life.png', label: 'Lifestyle'),
    Category(iconPath: 'assets/icons/pending.png', label: 'Time'),
  ];

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

  List<Task> _displayedTasks = [];
  int _selectedIndex = 0;
  TextEditingController categoryController = TextEditingController();

  String selectedCategoryLabel = 'Health';

  StreamSubscription<User?>? _authStateChangesSubscription;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainAdmin()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListuserSuspended()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListuserDeleteAdmin()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListuserPetition()),
        );
        break;
    }
  }

  Future<void> loadUserCategories() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    List<Category> currentCategories = List.from(_defaultCategories);

    if (uid != null) {
      try {
        final response = await http.get(
          Uri.parse(
              '${ApiEndpoints.baseUrl}/api/category/getCategory?uid=$uid'),
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
        selectedCategoryId = categories[0].id;
        _loadTasksForSelectedCategory();
      }
    });
  }

  Future<void> _loadTasksForSelectedCategory() async {
    final user = FirebaseAuth.instance.currentUser;
    List<Task> tasksToDisplay = [];
    if (_defaultTasksByCategory.containsKey(selectedCategoryLabel)) {
      tasksToDisplay.addAll(_defaultTasksByCategory[selectedCategoryLabel]!);
    }
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
                    act_id: int.tryParse(item['act_id'].toString()),
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
    print(uid);
    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/api/activity/getAct?uid=${uid}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((item) => Task(
                label: item['act_name'] ?? '',
                iconPath: item['act_pic'] ?? '',
                isNetworkImage: true,
              ))
          .toList();
    } else {
      throw Exception(
          'Failed to load activity with status: ${response.statusCode}');
    }
  }

  void _navigateToCreateActivityScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateActivityScreen(),
      ),
    );
    loadUserCategories();
  }

  Future<void> deleteActivity(
      String uid, int actId, BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/activity/deleteAct'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'act_id': actId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบกิจกรรมสำเร็จ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบกิจกรรมไม่สำเร็จ')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _authStateChangesSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      loadUserCategories();
    });
    loadUserCategories();
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: const Color(0xFF564843),
                height: MediaQuery.of(context).padding.top + 80,
                width: double.infinity,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF564843),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                ),
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ManageCategoriesDialog(
                                      onCategoriesUpdated: () {
                                        loadUserCategories();
                                      },
                                    ),
                                  );
                                  loadUserCategories();
                                },
                                child: Text(
                                  'จัดการหมวดหมู่',
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.map((category) {
                              bool isSelected =
                                  category.label == selectedCategoryLabel;
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCategoryLabel = category.label;
                                      selectedCategoryId = category.id;
                                      _loadTasksForSelectedCategory();
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
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: _displayedTasks.map((task) {
                          return TaskCard(
                            iconPath: task.iconPath,
                            label: task.label,
                            isNetworkImage: task.isNetworkImage,
                            act_id: task.act_id,
                            onEditComplete: () {
                              _loadTasksForSelectedCategory();
                            },
                            onDeleteComplete: () {
                              _loadTasksForSelectedCategory();
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
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
                            _navigateToCreateActivityScreen();
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFE6D2CD),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        selectedFontSize: 17,
        unselectedFontSize: 17,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedLabelStyle: GoogleFonts.kanit(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        unselectedLabelStyle: GoogleFonts.kanit(
          fontSize: 17,
          fontWeight: FontWeight.normal,
          color: Colors.white60,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/accout.png', width: 24, height: 24),
            label: 'User',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/deactivate.png', width: 30, height: 30),
            label: 'บัญชีที่ระงับ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/social-media-management.png', width: 24, height: 24), // เปลี่ยนไอคอน
            label: 'Manage', // เปลี่ยนข้อความ
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/wishlist-heart.png', width: 24, height: 24),
            label: 'คำร้อง',
          ),
        ],
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final bool isNetworkImage;
  // Removed: final Fu

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
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 24, color: Colors.grey),
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
          radius: 24, // ขนาดวงกลม
          child: ClipOval(child: imageWidget),
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

class TaskCard extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isNetworkImage;
  final int? act_id;
  final VoidCallback? onEditComplete;
  final VoidCallback? onDeleteComplete;

  const TaskCard({
    super.key,
    required this.iconPath,
    required this.label,
    this.isNetworkImage = false,
    this.act_id,
    this.onEditComplete,
    this.onDeleteComplete,
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
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditActivity(
                    actId: act_id!,
                    label: label,
                    iconPath: iconPath,
                    isNetworkImage: isNetworkImage,
                    uid: FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              );

              if (result == true) {
                if (onEditComplete != null) {
                  onEditComplete!();
                }
              }
            } else if (value == 'delete') {
              final uid = FirebaseAuth.instance.currentUser!.uid;
              final actId = act_id;
              if (actId != null) {
                try {
                  final response = await http.post(
                    Uri.parse('${ApiEndpoints.baseUrl}/api/activity/deleteAct'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'uid': uid, 'act_id': actId}),
                  );

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ลบกิจกรรมสำเร็จ: $label')),
                    );

                    if (onDeleteComplete != null) {
                      onDeleteComplete!();
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ลบกิจกรรมไม่สำเร็จ')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                  );
                }
              }
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
              builder: (context) => ChooseactivityPage(),
            ),
          );
        },
      ),
    );
  }
}
