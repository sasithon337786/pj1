import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/graph_all.dart'; // หน้าแสดงกราฟผลรวม (7 วัน + เดือน + ปี)
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';
import 'package:pj1/account.dart';
import 'package:pj1/user_Graph.dart'; // << หน้ารายละเอียดกิจกรรม (UserGraphBarScreen)

class Graphpage extends StatefulWidget {
  const Graphpage({super.key});

  @override
  State<Graphpage> createState() => _GraphpageState();
}

Future<List<Map<String, dynamic>>> fetchActivities() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final idToken = await user.getIdToken(true);
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $idToken',
    };

    final url = Uri.parse(
      '${ApiEndpoints.baseUrl}/api/activityDetail/getHistory',
    );

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final activities =
          List<Map<String, dynamic>>.from(json.decode(response.body));

      // เติม expectation ให้แต่ละ activity
      for (var act in activities) {
        final finalActId = _toInt(act['act_id'], fallback: 0);
        if (finalActId <= 0) {
          act['hasExpectation'] = false;
          act['user_exp'] = '';
          continue;
        }

        final expUrl = Uri.parse('${ApiEndpoints.baseUrl}/api/expuser/check');
        final expResp = await http.post(
          expUrl,
          headers: headers,
          body: jsonEncode({"act_id": finalActId, "uid": user.uid}),
        );

        if (expResp.statusCode == 200) {
          final data = jsonDecode(expResp.body);
          act['hasExpectation'] = data['exists'] == true;
          act['user_exp'] = data['user_exp'] ?? '';
        } else {
          act['hasExpectation'] = false;
          act['user_exp'] = '';
        }
      }

      return activities;
    } else {
      debugPrint(
          'fetchActivities failed: ${response.statusCode} ${response.body}');
      return [];
    }
  } catch (e) {
    debugPrint('fetchActivities error: $e');
    return [];
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  return fallback;
}

class _GraphpageState extends State<Graphpage> {
  int _selectedIndex = 2; // แท็บ Graph
  late final Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchActivities();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Targetpage()),
        );
        break;
      case 2:
        // อยู่หน้าเดิม
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topBarHeight = MediaQuery.of(context).padding.top + 80.0;

    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          // พื้นหลัง Top Bar
          Column(
            children: [
              Container(
                color: const Color(0xFF564843),
                height: topBarHeight,
                width: double.infinity,
              ),
              const Expanded(child: SizedBox()), // ดันด้านล่างให้เต็ม
            ],
          ),

          // เนื้อหา
          Column(
            children: [
              SizedBox(height: topBarHeight + 45),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    final activities = snap.data ?? [];
                    if (activities.isEmpty) {
                      return const Center(child: Text('ยังไม่มีกิจกรรม'));
                    }

                    // โครง: หัว + รายการเลื่อนเฉพาะ ListView
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEAE3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== หัว (นิ่ง) + ปุ่ม แสดงกราฟผลรวม =====
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/analysis.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'GRAPH',
                                  style: GoogleFonts.kanit(
                                    color: const Color(0xFFC98993),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFE6D2CD),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AllGraphScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.auto_graph,
                                    size: 18,
                                    color: Color(0xFFC98993),
                                  ),
                                  label: Text(
                                    'แสดงกราฟผลรวม',
                                    style: GoogleFonts.kanit(
                                      fontSize: 14,
                                      color: const Color(0xFFC98993),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // ===== รายการ (เลื่อนเฉพาะส่วนนี้) =====
                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: activities.length,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final act = activities[index];

                                  final actId = _toInt(act['act_id']);
                                  final actName =
                                      (act['act_name'] ?? '').toString();
                                  final actPic =
                                      (act['act_pic'] ?? '').toString();
                                  final expectationText =
                                      (act['user_exp'] ?? '') as String?;
                                  final actDetailId =
                                      _toInt(act['act_detail_id'], fallback: 0);

                                  return TaskCard(
                                    actId: actId,
                                    actName: actName,
                                    actPic: actPic,
                                    expectationText: expectationText,
                                    actDetailId:
                                        actDetailId == 0 ? null : actDetailId,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // โลโก้ (ซ้อนทับด้านบน)
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: MediaQuery.of(context).size.width / 2 - 40,
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
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

class TaskCard extends StatelessWidget {
  final int actId;
  final String actName;
  final String actPic;
  final String? expectationText;
  final int? actDetailId;

  const TaskCard({
    super.key,
    required this.actId,
    required this.actName,
    required this.actPic,
    this.expectationText,
    this.actDetailId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF564843),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            actPic,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, color: Colors.white),
          ),
        ),
        title: Text(
          actName,
          style: GoogleFonts.kanit(color: Colors.white, fontSize: 17),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE6D2CD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'รายละเอียด',
            style: GoogleFonts.kanit(
              color: const Color(0xFFC98993),
              fontSize: 14,
            ),
          ),
        ),
        onTap: () {
          // กลับไปแบบเดิม: กดรายการ -> ไปหน้า UserGraphBarScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserGraphBarScreen(
                actId: actId,
                actName: actName,
                actPic: actPic,
                expectationText: expectationText,
                actDetailId: actDetailId,
              ),
            ),
          );
        },
      ),
    );
  }
}
