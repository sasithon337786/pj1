import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/account.dart';
import 'package:pj1/add_expectations.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/user_expectations.dart';

class Targetpage extends StatefulWidget {
  const Targetpage({super.key});

  @override
  State<Targetpage> createState() => _TargetpageScreenState();
}

/// ===== Helpers ป้องกัน null/ชนิดไม่ตรง =====
int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

String _toString(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

/// ดึง activities พร้อมเช็คว่ามี expectation แล้วหรือยัง
Future<List<Map<String, dynamic>>> fetchActivitiesWithStatus() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final idToken = await user.getIdToken(true);
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $idToken',
    };

    // ✅ ดึง activities ของผู้ใช้ (ปลายทางนี้ของคุณ)
    final url = Uri.parse(
      '${ApiEndpoints.baseUrl}/api/activityDetail/getMyActivityDetails?uid=${user.uid}',
    );

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final activities =
          List<Map<String, dynamic>>.from(json.decode(response.body));

      // ✅ เติมสถานะ expectation ให้แต่ละ activity (ใช้ id ที่รองรับได้ทั้ง act_id/act_detail_id)
      for (var act in activities) {
        final finalActId =
            _toInt(act['act_id'] ?? act['act_detail_id'], fallback: 0);
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

class _TargetpageScreenState extends State<Targetpage> {
  int _selectedIndex = 1; // ตั้งค่าเริ่มต้นที่ Target page

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        // อยู่หน้าเดียวกัน
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
                  future: fetchActivitiesWithStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('ยังไม่มีกิจกรรม'));
                    }

                    // ✅ map ให้รองรับได้ทั้ง act_id/act_detail_id และ act_pic/icon_path
                    final normalized = snapshot.data!
                        .map((raw) {
                          final id = _toInt(
                              raw['act_id'] ?? raw['act_detail_id'],
                              fallback: 0);
                          if (id <= 0)
                            return null; // ตัดทิ้งรายการที่ไม่มี id ที่ใช้ได้
                          return {
                            'id': id,
                            'name': _toString(raw['act_name'],
                                fallback: 'Unknown Activity'),
                            'pic':
                                _toString(raw['act_pic'] ?? raw['icon_path']),
                          };
                        })
                        .where((e) => e != null)
                        .cast<Map<String, dynamic>>()
                        .toList();

                    if (normalized.isEmpty) {
                      return const Center(
                          child: Text('ยังไม่มีกิจกรรมที่ใช้งานได้'));
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 70, bottom: 16),
                      child: Column(
                        children: [
                          Container(
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
                                    Image.asset(
                                      'assets/images/expectional.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'EXPECTATIONS',
                                      style: GoogleFonts.kanit(
                                        color: const Color(0xFFC98993),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                for (var act in normalized)
                                  TaskCard(
                                    label: act['name'] as String,
                                    actId: act['id'] as int,
                                    actPic: act['pic'] as String,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
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

class TaskCard extends StatelessWidget {
  final String label;
  final int actId;
  final String actPic;

  const TaskCard({
    super.key,
    required this.label,
    required this.actId,
    required this.actPic,
  });

  Future<void> _handleTap(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final idToken = await user.getIdToken(true);
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $idToken',
    };

    try {
      final expUrl = Uri.parse('${ApiEndpoints.baseUrl}/api/expuser/check');
      final expResp = await http.post(
        expUrl,
        headers: headers,
        body: jsonEncode({"act_id": actId, "uid": user.uid}),
      );

      if (expResp.statusCode == 200) {
        final data = jsonDecode(expResp.body);
        final exists = data['exists'] == true;

        if (exists) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpectationResultScreen(
                actId: actId,
                expectationText: data['user_exp'] ?? '',
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ExpectationScreen(actId: actId, label: label, actPic: actPic),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการเช็คข้อมูล')),
        );
      }
    } catch (e) {
      debugPrint('Error checking expectation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เชื่อมต่อ API ไม่ได้')),
      );
    }
  }

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
          child: actPic.isEmpty
              ? const Icon(Icons.image_not_supported, color: Colors.white)
              : Image.network(
                  actPic,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.white),
                ),
        ),
        title: Text(
          label,
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
        onTap: () => _handleTap(context),
      ),
    );
  }
}
