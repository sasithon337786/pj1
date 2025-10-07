import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/graph_all.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';
import 'package:pj1/account.dart';
import 'package:pj1/user_Graph.dart';

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

    // ดึง activities ของผู้ใช้
    final url = Uri.parse(
      '${ApiEndpoints.baseUrl}/api/activityDetail/getMyActivityDetails?uid=${user.uid}',
    );

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final activities =
          List<Map<String, dynamic>>.from(json.decode(response.body));

      // เติมสถานะ expectation ให้แต่ละ activity
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

// ตัวช่วยแปลงค่าเป็น int
int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  if (value is double) return value.toInt();
  return fallback;
}

class _GraphpageState extends State<Graphpage> {
  int _selectedIndex = 2; // อยู่แท็บ Graph
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
            context, MaterialPageRoute(builder: (_) => const HomePage()));
        break;
      case 1:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Targetpage()));
        break;
      case 2:
        // อยู่หน้าเดิม
        break;
      case 3:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AccountPage()));
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

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 70, bottom: 16),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEAE3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset('assets/images/analysis.png',
                                    width: 24, height: 24),
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
                                // ปุ่มใหม่
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
                                          builder: (_) =>
                                              const AllGraphScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.auto_graph,
                                      size: 18, color: Color(0xFFC98993)),
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
                            const SizedBox(height: 16),
                            // ----------------------------------
                            const SizedBox(height: 16),
                            for (final act in activities)
                              TaskCard(
                                actId: (act['act_id'] as num).toInt(),
                                actName: (act['act_name'] ?? '').toString(),
                                actPic: (act['act_pic'] ?? '').toString(),
                                expectationText: act['user_exp'] ?? '',
                                actDetailId:
                                    (act['act_detail_id'] as num?)?.toInt(),
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
          // โลโก้
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: MediaQuery.of(context).size.width / 2 - 40,
            child: ClipOval(
              child: Image.asset('assets/images/logo.png',
                  width: 80, height: 80, fit: BoxFit.cover),
            ),
          ),
          // ปุ่มย้อนกลับ
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const HomePage()));
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
        title: Text(actName,
            style: GoogleFonts.kanit(color: Colors.white, fontSize: 17)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE6D2CD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('รายละเอียด',
              style: GoogleFonts.kanit(
                  color: const Color(0xFFC98993), fontSize: 14)),
        ),
        onTap: () {
          // เพิ่ม debug print เพื่อตรวจสอบค่าที่ส่ง
          debugPrint('TaskCard tapped:');
          debugPrint('actId: $actId');
          debugPrint('actName: $actName');
          debugPrint('actPic: $actPic');
          debugPrint('expectationText: $expectationText');
          debugPrint('actDetailId: $actDetailId');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserGraphBarScreen(
                actId: actId, // int
                actName: actName, // String
                actPic: actPic, // String
                expectationText: expectationText, // String
                actDetailId: actDetailId, // int
              ),
            ),
          );
        },
      ),
    );
  }
}
