import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pj1/account.dart';
import 'package:pj1/calendar_page.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/set_time.dart';
import 'package:pj1/target.dart';

class DoingActivity extends StatefulWidget {
  const DoingActivity({super.key});

  @override
  State<DoingActivity> createState() => _DoingActivityState();
}

class _DoingActivityState extends State<DoingActivity> {
  int _selectedIndex = 0;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  void _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
      print('Current User UID: $currentUserId');
    } else {
      print('No user is currently logged in.');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserActivities() async {
    if (currentUserId == null) return [];

    try {
      final detailResponse = await http.get(
        Uri.parse(
            'https://95544ee3ed3a.ngrok-free.app/api/activityDetail/activity-detail?uid=$currentUserId'),
      );

      if (detailResponse.statusCode != 200) {
        print(
            'Failed to fetch activity detail. Status: ${detailResponse.statusCode}');
        return [];
      }

      final List<dynamic> detailList = jsonDecode(detailResponse.body);
      print('Activity Detail Data: $detailList');

      final activityResponse = await http.get(
        Uri.parse(
            'https://95544ee3ed3a.ngrok-free.app/api/activity/getAct?uid=$currentUserId'),
      );

      if (activityResponse.statusCode != 200) {
        print(
            'Failed to fetch activity master. Status: ${activityResponse.statusCode}');
        return [];
      }

      final List<dynamic> activityList = jsonDecode(activityResponse.body);
      print('Activity Master Data: $activityList');

      Map<String, Map<String, dynamic>> activityMap = {};
      for (var activity in activityList) {
        String actId = activity['act_id'].toString();
        activityMap[actId] = {
          'act_name': activity['act_name'],
          'icon_path': activity['act_pic'],
        };
      }

      List<Map<String, dynamic>> combinedList = [];
      for (var detail in detailList) {
        String actId = detail['act_id'].toString();
        var activityData = activityMap[actId];

        combinedList.add({
          'act_detail_id': detail['act_detail_id'].toString(),
          'act_name': activityData != null
              ? activityData['act_name']
              : 'Unknown Activity',
          'icon_path':
              activityData != null ? activityData['icon_path'] ?? '' : '',
          'goal': detail['goal']?.toString() ?? '-', // <-- เพิ่ม goal เข้ามา
        });
      }

      return combinedList;
    } catch (e) {
      print('Error fetching user activities: $e');
      return [];
    }
  }

  Future<void> _deleteActivity(String actDetailId) async {
    final response = await http.delete(
      Uri.parse(
          'https://67a98d9641d0.ngrok-free.app/api/activityDetail/activity-detail/$actDetailId'),
    );

    if (response.statusCode == 200) {
      print('Activity deleted successfully.');
      setState(() {}); // Refresh หน้า
    } else {
      print('Failed to delete activity. Status: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบกิจกรรมไม่สำเร็จ')),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const HomePage()));
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Targetpage()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Graphpage()));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AccountPage()));
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
              Container(
                color: const Color(0xFF564843),
                height: MediaQuery.of(context).padding.top + 80,
                width: double.infinity,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF564843),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CalendarPage()));
                        },
                        icon: const Icon(Icons.calendar_month,
                            color: Colors.white, size: 16),
                        label: Text('ปฏิทินความสำเร็จ',
                            style: GoogleFonts.kanit(
                                color: Colors.white, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Image.asset('assets/icons/profile.png',
                            width: 24, height: 24),
                        const SizedBox(width: 8),
                        Text('Your Activity',
                            style: GoogleFonts.kanit(
                                color: Colors.white, fontSize: 24)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchUserActivities(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                            'Failed to load activities: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white)),
                      );
                    } else if (snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No activities found.',
                            style: TextStyle(color: Colors.white)),
                      );
                    } else {
                      final activities = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activityData = activities[index];
                          final String iconPath =
                              activityData['icon_path'] ?? '';
                          final String label =
                              activityData['act_name'] ?? 'Unknown Activity';
                          final String actDetailId =
                              activityData['act_detail_id'];
                          final bool isNetworkImage =
                              iconPath.startsWith('http');
                          final String goal = activityData['goal'] ?? '-';
                          return TaskCard(
                            iconPath: iconPath,
                            label: label,
                            goal: goal, // <-- ส่ง goal
                            isNetworkImage: isNetworkImage,
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CountdownPage()));
                            },
                            onDelete: () {
                              _showDeleteConfirmationDialog(actDetailId);
                            },
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: ClipOval(
              child: Image.asset('assets/images/logo.png',
                  width: 100, height: 100, fit: BoxFit.cover),
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
                  const Icon(Icons.arrow_back, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('ย้อนกลับ',
                      style:
                          GoogleFonts.kanit(color: Colors.white, fontSize: 16)),
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
              label: 'Add'),
          BottomNavigationBarItem(
              icon: Image.asset('assets/icons/wishlist-heart.png',
                  width: 24, height: 24),
              label: 'Target'),
          BottomNavigationBarItem(
              icon:
                  Image.asset('assets/icons/stats.png', width: 24, height: 24),
              label: 'Graph'),
          BottomNavigationBarItem(
              icon:
                  Image.asset('assets/icons/accout.png', width: 24, height: 24),
              label: 'Account'),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String iconPath;
  final String label;
  final String goal; // <-- เพิ่ม goal เข้ามา
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isNetworkImage;

  const TaskCard({
    Key? key,
    required this.iconPath,
    required this.label,
    required this.goal, // <-- เพิ่ม goal
    this.onTap,
    this.onDelete,
    this.isNetworkImage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (isNetworkImage) {
      imageWidget = iconPath.isEmpty
          ? Image.asset('assets/images/no_image.png',
              width: 48, height: 48, fit: BoxFit.contain)
          : Image.network(iconPath, width: 48, height: 48, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/images/no_image.png',
                  width: 48, height: 48, fit: BoxFit.contain);
            });
    } else {
      imageWidget = iconPath.isEmpty
          ? Image.asset('assets/images/no_image.png',
              width: 48, height: 48, fit: BoxFit.contain)
          : Image.asset(iconPath, width: 48, height: 48, fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/images/no_image.png',
                  width: 48, height: 48, fit: BoxFit.contain);
            });
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
          style:
              GoogleFonts.kanit(fontSize: 20, color: const Color(0xFFC98993)),
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
                    color: const Color.fromARGB(255, 250, 250, 250)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete,
                  color: Color.fromARGB(255, 206, 40, 40)),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
