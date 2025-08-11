import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:pj1/account.dart';
import 'package:pj1/add.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/target.dart';
import 'package:pj1/constant/api_endpoint.dart'; // ใช้ baseUrl เดียวกันทุกที่

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  String? currentUserId;
  late Future<List<Map<String, dynamic>>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _initAuthAndLoad();
  }

  void _initAuthAndLoad() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      _activitiesFuture = _fetchUserActivities();
    } else {
      currentUserId = null;
      _activitiesFuture = Future.value([]); // ยังไม่ล็อกอิน ให้เป็นลิสต์ว่าง
    }
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _fetchUserActivities() async {
    if (currentUserId == null) return [];

    try {
      final detailUrl =
          '${ApiEndpoints.baseUrl}/api/activityDetail/activity-detail?uid=$currentUserId';
      final actUrl =
          '${ApiEndpoints.baseUrl}/api/activity/getAct?uid=$currentUserId';

      final detailResponse = await http
          .get(Uri.parse(detailUrl))
          .timeout(const Duration(seconds: 12));
      if (detailResponse.statusCode != 200) return [];

      final List<dynamic> detailList = jsonDecode(detailResponse.body);

      final activityResponse = await http
          .get(Uri.parse(actUrl))
          .timeout(const Duration(seconds: 12));
      if (activityResponse.statusCode != 200) return [];

      final List<dynamic> activityList = jsonDecode(activityResponse.body);

      // map act_id -> {name, icon}
      final Map<String, Map<String, dynamic>> activityMap = {};
      for (var activity in activityList) {
        final actId = activity['act_id']?.toString() ?? '';
        activityMap[actId] = {
          'act_name': activity['act_name'],
          'icon_path': activity['act_pic'],
        };
      }

      // รวมข้อมูล detail + master
      final List<Map<String, dynamic>> combined = [];
      for (var detail in detailList) {
        final actId = detail['act_id']?.toString() ?? '';
        final master = activityMap[actId];

        combined.add({
          'act_detail_id': detail['act_detail_id']?.toString() ?? '',
          'act_name': master?['act_name'] ?? 'Unknown Activity',
          'icon_path': master?['icon_path'] ?? '',
          'goal': detail['goal']?.toString() ?? '-',
        });
      }

      return combined;
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เชื่อมต่อนานเกินไป ลองใหม่อีกครั้ง')),
      );
      return [];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
      return [];
    }
  }

  Future<void> _deleteActivity(String actDetailId) async {
    try {
      final delUrl =
          '${ApiEndpoints.baseUrl}/api/activityDetail/activity-detail/$actDetailId';
      final response = await http
          .delete(Uri.parse(delUrl))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        _reload();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบกิจกรรมไม่สำเร็จ')),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เชื่อมต่อนานเกินไป ลองใหม่อีกครั้ง')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _showDeleteConfirmationDialog(String actDetailId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFF3E1E1),
        title: Text('ยืนยันการลบ',
            style: GoogleFonts.kanit(color: const Color(0xFF564843))),
        content: Text('คุณต้องการลบกิจกรรมนี้หรือไม่?',
            style: GoogleFonts.kanit(color: const Color(0xFF564843))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก',
                style: GoogleFonts.kanit(color: const Color(0xFFC98993))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteActivity(actDetailId);
            },
            child: Text('ลบ',
                style: GoogleFonts.kanit(color: const Color(0xFF564843))),
          ),
        ],
      ),
    );
  }

  void _reload() {
    setState(() {
      _activitiesFuture = _fetchUserActivities();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        // หน้านี้คือ Home อยู่แล้ว ถ้าอยากให้ไปหน้า Add ให้เปลี่ยนเป็น AddPage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainHomeScreen()),
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
    final isLoggedIn = currentUserId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          Column(
            children: [
              // แถบหัว
              Container(
                color: const Color(0xFF564843),
                height: MediaQuery.of(context).padding.top + 80,
                width: double.infinity,
              ),

              // เนื้อหา
              Expanded(
                child: isLoggedIn
                    ? FutureBuilder<List<Map<String, dynamic>>>(
                        future: _activitiesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final items = snapshot.data ?? [];
                          final hasActivities = items.isNotEmpty;

                          if (!hasActivities) {
                            // ล็อกอินแล้ว แต่ยังไม่มี activity
                            return Center(
                              child: Text(
                                'กดไอคอน Add เพิ่ม Activity ของคุณกัน',
                                style: GoogleFonts.kanit(
                                    fontSize: 18, color: Colors.white),
                              ),
                            );
                          }

                          // ล็อกอิน + มี activity → แสดงลิสต์ (DoingActivity เดิม)
                          return RefreshIndicator(
                            onRefresh: () async => _reload(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: items.length + 1, // +1 สำหรับหัวข้อ
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        top: 50, bottom: 12),
                                    child: Row(
                                      children: [
                                        Image.asset('assets/icons/profile.png',
                                            width: 24, height: 24),
                                        const SizedBox(width: 8),
                                        Text('Your Activity',
                                            style: GoogleFonts.kanit(
                                                color: Colors.white,
                                                fontSize: 24)),
                                      ],
                                    ),
                                  );
                                }

                                final activity = items[index - 1];
                                final iconPath =
                                    (activity['icon_path'] ?? '') as String;
                                final isNetwork = iconPath.startsWith('http');
                                final label =
                                    (activity['act_name'] ?? '') as String;
                                final goal =
                                    (activity['goal'] ?? '-') as String;
                                final actDetailId =
                                    (activity['act_detail_id'] ?? '') as String;

                                return _TaskCard(
                                  iconPath: iconPath,
                                  isNetworkImage: isNetwork,
                                  label: label,
                                  goal: goal,
                                  onDelete: () => _showDeleteConfirmationDialog(
                                      actDetailId),
                                  onTap: () {
                                    // ถ้าจะไปหน้าโหมดจับเวลา/บันทึก ทำที่นี่
                                  },
                                );
                              },
                            ),
                          );
                        },
                      )
                    : Center(
                        // ยังไม่ล็อกอิน → ข้อความตามที่หนูต้องการ
                        child: Text(
                          'กดไอคอน Add เพิ่ม Activity ของคุณกัน',
                          style: GoogleFonts.kanit(
                              fontSize: 18, color: Colors.white),
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

          // ปุ่มย้อนกลับ (ถ้าหนูไม่อยากให้มีใน Home ก็ลบทิ้งได้)
          // Positioned(
          //   top: MediaQuery.of(context).padding.top + 16,
          //   left: 16,
          //   child: GestureDetector(
          //     onTap: () => Navigator.maybePop(context),
          //     child: Row(
          //       children: [
          //         const Icon(Icons.arrow_back, color: Colors.white),
          //         const SizedBox(width: 6),
          //         Text(
          //           'ย้อนกลับ',
          //           style: GoogleFonts.kanit(color: Colors.white, fontSize: 16),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),

      // แถบล่าง
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

/// การ์ดกิจกรรม (ย้ายมาจาก DoingActivity)
class _TaskCard extends StatelessWidget {
  final String iconPath;
  final String label;
  final String goal;
  final bool isNetworkImage;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _TaskCard({
    required this.iconPath,
    required this.label,
    required this.goal,
    required this.isNetworkImage,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (isNetworkImage) {
      imageWidget = iconPath.isEmpty
          ? Image.asset('assets/images/no_image.png',
              width: 48, height: 48, fit: BoxFit.contain)
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                iconPath,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/no_image.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            );
    } else {
      imageWidget = iconPath.isEmpty
          ? Image.asset('assets/images/no_image.png',
              width: 48, height: 48, fit: BoxFit.contain)
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                iconPath,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/no_image.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            );
    }

    return Card(
      color: const Color(0xFFF3E1E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: imageWidget,
        title: Text(
          label,
          style: GoogleFonts.kanit(
            fontSize: 20,
            color: const Color(0xFFC98993),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF564843),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Goal: $goal',
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  color: const Color(0xFFFAFAFA),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFCE2828)),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
