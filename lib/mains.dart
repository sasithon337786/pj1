import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pj1/Increase_activity.dart';

import 'package:pj1/account.dart';
import 'package:pj1/add.dart';
import 'package:pj1/calendar_page.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/set_time.dart';
import 'package:pj1/target.dart';
import 'package:pj1/constant/api_endpoint.dart';

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

  // ✅ helper: สร้าง headers พร้อม Bearer token
  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken(true); // refresh เสมอ
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  void _goToCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarPage()),
    );
  }

  bool _isTimeUnit(String? unitRaw) {
    if (unitRaw == null) return false;
    final u = unitRaw.trim().toLowerCase();
    const timeUnits = {
      'วินาที',
      'นาที',
      'ชั่วโมง',
      'sec',
      'second',
      'secs',
      'seconds',
      'min',
      'minute',
      'mins',
      'minutes',
      'hr',
      'hour',
      'hrs',
      'hours',
    };
    return timeUnits.contains(u);
  }

  void _initAuthAndLoad() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      _activitiesFuture = _fetchUserActivities();
    } else {
      currentUserId = null;
      _activitiesFuture = Future.value([]);
    }
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _fetchUserActivities() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    try {
      final idToken = await currentUser.getIdToken(true); // refresh token เสมอ

      // เรียก API เดียว
      final detailUri = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityDetail/getMyActivityDetails',
      );
      final response = await http.get(
        detailUri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return [];
      final List<dynamic> detailList = jsonDecode(response.body);

      String _fmt(num n) => (n % 1 == 0) ? n.toInt().toString() : n.toString();

      final List<Map<String, dynamic>> activities = [];

      for (var detail in detailList) {
        final double goal = (detail['goal'] is num)
            ? (detail['goal'] as num).toDouble()
            : double.tryParse(detail['goal']?.toString() ?? '0') ?? 0;

        // 👇 current_value ไม่ได้มาจาก API นี้แล้ว
        final double current = 0;

        final String unit = detail['unit']?.toString() ?? '';

        activities.add({
          'act_detail_id': detail['act_detail_id']?.toString() ?? '',
          'act_name': detail['act_name'] ?? 'Unknown Activity',
          'icon_path': detail['act_pic'] ?? '',
          'goal': goal,
          'unit': unit,
          'current_value': current,
          'is_completed': false, // คำนวณทีหลังหลังได้ current จริง
        });
      }

      return activities;
    } catch (e) {
      debugPrint("Error fetching user activities: $e");
      return [];
    }
  }

  Future<int> _fetchCurrentValue(String actDetailId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 0;

    final idToken = await currentUser.getIdToken();
    final url = Uri.parse(
      '${ApiEndpoints.baseUrl}/api/activityHistory/getTodayCurrentValue?act_detail_id=$actDetailId',
    );

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['current_value'] ?? 0;
    }
    return 0;
  }

  Future<void> _deleteActivity(String actDetailId) async {
    try {
      final delUrl =
          '${ApiEndpoints.baseUrl}/api/activityDetail/deleteActivityDetail?act_detail_id=${Uri.encodeComponent(actDetailId)}';
      final response = await http
          .delete(
            Uri.parse(delUrl),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        _reload();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบกิจกรรมเรียบร้อย')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('ลบกิจกรรมไม่สำเร็จ (${response.statusCode})')),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เชื่อมต่อนานเกินไป ลองใหม่อีกครั้ง')),
      );
    } catch (e) {
      if (!mounted) return;
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
              Container(
                color: const Color(0xFF564843),
                height: MediaQuery.of(context).padding.top + 80,
                width: double.infinity,
              ),
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
                            return Center(
                              child: Text(
                                'กดไอคอน Add เพิ่ม Activity ของคุณกัน',
                                style: GoogleFonts.kanit(
                                    fontSize: 18, color: Colors.white),
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async => _reload(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: items.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        top: 50, bottom: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Image.asset('assets/icons/accc.png',
                                                width: 30, height: 30),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Your Activity',
                                              style: GoogleFonts.kanit(
                                                  color: Colors.white,
                                                  fontSize: 24),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: _goToCalendar,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF564843),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            elevation: 0,
                                          ),
                                          icon: const Icon(Icons.calendar_today,
                                              size: 16, color: Colors.white),
                                          label: Text(
                                            'ปฏิทินความสำเร็จ',
                                            style: GoogleFonts.kanit(
                                                color: Colors.white,
                                                fontSize: 14),
                                          ),
                                        ),
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

                                final unit =
                                    (activity['unit'] ?? '').toString();
                                final actDetailId =
                                    (activity['act_detail_id'] ?? '') as String;
                                final displayText =
                                    (activity['display_text'] ?? '') as String;
                                final isCompleted =
                                    (activity['is_completed'] ?? false) as bool;

                                return _TaskCard(
                                  iconPath: iconPath,
                                  isNetworkImage: isNetwork,
                                  label: label,
                                  displayText: displayText,
                                  isCompleted: isCompleted,
                                  onDelete: () => _showDeleteConfirmationDialog(
                                      actDetailId),
                                  onTap: () async {
                                    if (_isTimeUnit(unit)) {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CountdownPage(
                                            actDetailId: actDetailId,
                                            actName: label,
                                            goal: (activity['goal'] ?? '')
                                                .toString(),
                                            unit: unit,
                                            imageSrc: iconPath,
                                          ),
                                        ),
                                      );
                                      if (result == true && mounted) _reload();
                                    } else {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => Increaseactivity(
                                            actDetailId: actDetailId,
                                            actName: label,
                                            goal: (activity['goal'] ?? '')
                                                .toString(),
                                            unit: unit,
                                            imageSrc: iconPath,
                                          ),
                                        ),
                                      );
                                      if (result == true && mounted) _reload();
                                    }
                                  },
                                );
                              },
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'กดไอคอน Add เพิ่ม Activity ของคุณกัน',
                          style: GoogleFonts.kanit(
                              fontSize: 18, color: Colors.white),
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

class _TaskCard extends StatelessWidget {
  final String iconPath;
  final String label;
  final String displayText;
  final bool isCompleted;
  final bool isNetworkImage;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _TaskCard({
    required this.iconPath,
    required this.label,
    required this.displayText,
    required this.isCompleted,
    required this.isNetworkImage,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = isNetworkImage
        ? (iconPath.isEmpty
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
                      fit: BoxFit.contain),
                ),
              ))
        : (iconPath.isEmpty
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
                      fit: BoxFit.contain),
                ),
              ));

    final Color chipColor =
        isCompleted ? const Color(0xFFC98993) : const Color(0xFF564843);

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
                  color: chipColor, borderRadius: BorderRadius.circular(12)),
              child: Text(
                displayText,
                style: GoogleFonts.kanit(
                    fontSize: 14, color: const Color(0xFFFAFAFA)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFCE2828)),
              onPressed: onDelete,
              tooltip: 'ลบกิจกรรม',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
