import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/add.dart';
import 'package:pj1/chooseactivity.dart';
import 'package:pj1/custom_Activity.dart';
import 'package:pj1/dialog_coagy.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/lifestly_Activity.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/sport_Activity.dart';
import 'package:pj1/target.dart';

class TimeActivity extends StatefulWidget {
  const TimeActivity({super.key});

  @override
  State<TimeActivity> createState() => _TimeActivityPageState();
}

class _TimeActivityPageState extends State<TimeActivity> {
  int _selectedIndex = 0; // กำหนดค่าเริ่มต้นให้กับ _selectedIndex
  TextEditingController categoryController = TextEditingController();
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Targetpage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Graphpage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          Column(
            children: [
              // Top bar แบบเดียวกับ HomePage
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
                              showAddCategoryDialog(context, categoryController,
                                  (File image, String categoryName) {
                                // ทำอะไรก็ได้เมื่อกด complete เช่น
                                print('ได้รูป: ${image.path}');
                                print('ชื่อหมวดหมู่: $categoryName');
                              });
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
                      // หมวด icon
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MainHomeScreen()),
                                );
                              },
                              child: CategoryIcon(
                                icon: 'assets/icons/heart-health-muscle.png',
                                label: 'Health',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SportActivityPage()),
                                );
                              },
                              child: CategoryIcon(
                                icon: 'assets/icons/gym.png',
                                label: 'Sports',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          LifestyleActivity()),
                                );
                              },
                              child: CategoryIcon(
                                icon: 'assets/icons/life.png',
                                label: 'Lifestyle',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TimeActivity()),
                                );
                              },
                              child: CategoryIcon(
                                icon: 'assets/icons/pending.png',
                                label: 'Time',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Task list
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: const [
                          TaskCard(
                            iconPath: 'assets/images/sheet-mask.png',
                            label: 'Facial mask',
                          ),
                          TaskCard(
                            iconPath: 'assets/images/skincare-routine.png',
                            label: 'Routine',
                          ),
                          TaskCard(
                            iconPath: 'assets/images/hair-dryer.png',
                            label: 'Hair routine',
                          ),
                          TaskCard(
                            iconPath: 'assets/images/popcorn.png',
                            label: 'Free Time',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Custom button
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF5E4A47),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateActivityScreen()),
                            );
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
          // โลโก้ Positioned เหมือนหน้า HomePage
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

class CategoryIcon extends StatelessWidget {
  final String icon; // เปลี่ยนจาก IconData เป็น String สำหรับ path รูปภาพ
  final String label;

  const CategoryIcon({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE6D2C0),
          radius: 24,
          child: Image.asset(
            icon,
            width: 24, // ขนาดของไอคอน
            height: 24,
            fit: BoxFit.contain, // ให้รูปอยู่ในขอบเขตของ CircleAvatar
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.kanit(
              fontSize: 12, color: Colors.white), // เปลี่ยนสีข้อความเป็นขาว
        ),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  final String iconPath;
  final String label;

  const TaskCard({
    super.key,
    required this.iconPath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF3E1E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Image.asset(
              iconPath,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16), // ระยะห่างระหว่างรูปกับข้อความ
            Text(
              label,
              style: GoogleFonts.kanit(fontSize: 20, color: Color(0xFFC98993)),
            ),
          ],
        ),
        trailing: const Icon(Icons.add, color: Color(0xFFC98993)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChooseactivityPage()),
          );
        },
      ),
    );
  }
}
