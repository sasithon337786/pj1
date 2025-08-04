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
import 'package:pj1/account.dart';
import 'package:pj1/chooseactivity.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/custom_Activity.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/manage_categories_dialog.dart';
import 'package:pj1/target.dart';
import 'package:pj1/edit_activity.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class Category {
  final int? id;
  final String iconPath;
  final String label;
  final bool isNetworkImage;

  Category({
    this.id,
    required this.iconPath,
    required this.label,
    this.isNetworkImage = false,
  });
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

class _MainHomeScreenState extends State<MainHomeScreen> {
  List<Category> categories = [];
  List<Task> _displayedTasks = [];
  int? selectedCategoryId;
  String selectedCategoryLabel = '';
  int _selectedIndex = 0;
  TextEditingController categoryController = TextEditingController();
  StreamSubscription<User?>? _authStateChangesSubscription;
  String? userRole;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (userRole == 'admin') {
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainAdmin()),
          );
          break;
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ListuserSuspended()),
          );
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const ListuserDeleteAdmin()),
          );
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ListuserPetition()),
          );
          break;
      }
    } else {
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
  }

  // ฟังก์ชันสำหรับดึง role ของผู้ใช้
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

  // ฟังก์ชันสำหรับโหลดหมวดหมู่จาก backend
  Future<void> loadUserCategories() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final role = await _getUserRole(uid);
      http.Response response;

      if (role == 'admin') {
        response = await http.get(
          Uri.parse(
              '${ApiEndpoints.baseUrl}/api/adminCate/getDefaultCategories'),
        );
      } else {
        response = await http.get(
          Uri.parse(
              '${ApiEndpoints.baseUrl}/api/category/getCategory?uid=$uid'),
        );
      }

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
          categories = categoriesData;
          if (categories.isNotEmpty) {
            selectedCategoryLabel = categories[0].label;
            selectedCategoryId = categories[0].id;
            _loadTasksForSelectedCategory();
          }
        });
      } else {
        print('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // ฟังก์ชันสำหรับโหลดกิจกรรมจาก backend
  Future<void> _loadTasksForSelectedCategory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || selectedCategoryId == null) return;

    try {
      final role = await _getUserRole(user.uid);
      http.Response response;

      if (role == 'admin') {
        response = await http.get(
          Uri.parse(
              '${ApiEndpoints.baseUrl}/api/adminAct/getDefaultActivity?cate_id=$selectedCategoryId'),
        );
      } else {
        response = await http.get(
          Uri.parse(
              '${ApiEndpoints.baseUrl}/api/activity/getAct?uid=${user.uid}&cate_id=$selectedCategoryId'),
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tasks = (data as List).map((item) {
          return Task(
            iconPath: item['act_pic'],
            label: item['act_name'],
            isNetworkImage: true,
            act_id: int.tryParse(item['act_id'].toString()),
          );
        }).toList();

        setState(() {
          _displayedTasks = tasks;
        });
      } else {
        print('Failed to load activities: ${response.statusCode}');
        setState(() {
          _displayedTasks = [];
        });
      }
    } catch (e) {
      print('Error loading activities for categoryId $selectedCategoryId: $e');
      setState(() {
        _displayedTasks = [];
      });
    }
  }

  // ฟังก์ชันสำหรับดึงกิจกรรมทั้งหมดจาก backend
  Future<List<Task>> getTasksFromDatabase(String uid) async {
    try {
      final role = await _getUserRole(uid);
      String apiUrl;

      if (role == 'admin') {
        apiUrl = '${ApiEndpoints.baseUrl}/api/adminAct/getDefaultActivity';
      } else {
        apiUrl = '${ApiEndpoints.baseUrl}/api/activity/getAct?uid=$uid';
      }

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => Task(
                  label: item['act_name'] ?? '',
                  iconPath: item['act_pic'] ?? '',
                  isNetworkImage: true,
                  act_id: int.tryParse(item['act_id'].toString()),
                ))
            .toList();
      } else {
        throw Exception(
            'Failed to load activity with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading tasks: $e');
    }
  }

  // ฟังก์ชันสำหรับลบกิจกรรม
  Future<void> deleteActivity(
      String uid, int actId, BuildContext context) async {
    try {
      final role = await _getUserRole(uid);
      String deleteUrl;

      if (role == 'admin') {
        deleteUrl =
            '${ApiEndpoints.baseUrl}/api/adminAct/deleteDefaultActivity';
      } else {
        deleteUrl = '${ApiEndpoints.baseUrl}/api/activity/deleteAct';
      }

      final response = await http.post(
        Uri.parse(deleteUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'act_id': actId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบกิจกรรมสำเร็จ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบกิจกรรมไม่สำเร็จ')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
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

  @override
  void initState() {
    super.initState();
    _authStateChangesSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadUserCategories();
        _getUserRole(user.uid).then((role) {
          setState(() {
            userRole = role;
          });
        });
      }
    });
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
                      // ปุ่มจัดการหมวดหมู่
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
                              await showDialog(
                                context: context,
                                builder: (context) => ManageCategoriesDialog(
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      // แสดงหมวดหมู่
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
                      // แสดงกิจกรรม
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
                      // ปุ่มสร้างกิจกรรมใหม่
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
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white),
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
        items: userRole == 'admin'
            ? [
                BottomNavigationBarItem(
                  icon: Image.asset('assets/icons/accout.png',
                      width: 24, height: 24),
                  label: 'User',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset('assets/icons/deactivate.png',
                      width: 30, height: 30),
                  label: 'บัญชีที่ระงับ',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset('assets/icons/social-media-management.png',
                      width: 24, height: 24),
                  label: 'Manage',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset('assets/icons/wishlist-heart.png',
                      width: 24, height: 24),
                  label: 'คำร้อง',
                ),
              ]
            : [
                BottomNavigationBarItem(
                  icon: Image.asset('assets/icons/add.png',
                      width: 24, height: 24),
                  label: 'Add',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset('assets/icons/wishlist-heart.png',
                      width: 24, height: 24),
                  label: 'Target',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset('assets/icons/stats.png',
                      width: 24, height: 24),
                  label: 'Graph',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset('assets/icons/accout.png',
                      width: 24, height: 24),
                  label: 'Account',
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
          backgroundColor:
              isSelected ? const Color(0xFF564843) : const Color(0xFFE6D2C0),
          radius: 24,
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

  Future<String?> _getUserRole(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/getRole?uid=$uid'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
                fontSize: 20,
                color: const Color(0xFFC98993),
              ),
            ),
          ],
        ),
        trailing: act_id != null
            ? PopupMenuButton<String>(
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

                    if (result == true && onEditComplete != null) {
                      onEditComplete!();
                    }
                  } else if (value == 'delete') {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    try {
                      final role = await _getUserRole(uid);
                      String deleteUrl;

                      if (role == 'admin') {
                        deleteUrl =
                            '${ApiEndpoints.baseUrl}/api/adminAct/deleteDefaultActivity';
                      } else {
                        deleteUrl =
                            '${ApiEndpoints.baseUrl}/api/activity/deleteAct';
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              backgroundColor: Colors.black54,
                            ),
                          );
                        },
                      );

                      final response = await http.post(
                        Uri.parse(deleteUrl),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'uid': uid, 'act_id': act_id}),
                      );

                      Navigator.pop(context);

                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ลบกิจกรรมสำเร็จ: $label')),
                        );
                        if (onDeleteComplete != null) {
                          onDeleteComplete!();
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ลบกิจกรรมไม่สำเร็จ')),
                        );
                      }
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                      );
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
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChooseactivityPage(
                actId: act_id,
                activityName: label,
                activityIconPath: iconPath, // *** ส่ง iconPath ไปด้วย ***
                isNetworkImage: isNetworkImage,
              ),
            ),
          );
        },
      ),
    );
  }
}
