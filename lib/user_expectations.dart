import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/account.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';

class ExpectationResultScreen extends StatefulWidget {
  final int actId;
  final String expectationText;
  final int actDetailId;
  // ถ้าไม่ใช้ percentTarget ให้ลบออก

  const ExpectationResultScreen({
    super.key,
    required this.actId,
    required this.expectationText,
    required this.actDetailId,
  });

  @override
  State<ExpectationResultScreen> createState() =>
      _ExpectationResultScreenState();
}

class _ExpectationResultScreenState extends State<ExpectationResultScreen> {
  int _selectedIndex = 0;
  bool isLoading = true;
  double? _percent;
  // final int actId;
  final TextEditingController expectationController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // ✅ ใช้ค่าที่ส่งมาทันที
    expectationController.text = widget.expectationText;
    fetchPercent(widget.actDetailId);
  }

  Future<void> fetchExpectation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final idToken = await user.getIdToken(true);
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/expuser/getuidex?uid=${user.uid}&act_id=${widget.actId}',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          expectationController.text =
              data.isNotEmpty ? data[0]['user_exp'] ?? '' : '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        debugPrint("Error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("fetchExpectation error: $e");
      setState(() => isLoading = false);
    }
  }

  // ฟังก์ชันดึง percent จาก API
  Future<void> fetchPercent(int actDetailId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final idToken = await user.getIdToken(true);
    final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityHistory/getTodaySum?act_detail_id=$actDetailId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      double percent = (data['percent'] ?? 0).toDouble();
      setState(() {
        _percent = percent; // ✅ อัปเดตตัวแปร
      });
      print('Percent: $percent');
    } else {
      print('Failed to fetch percent: ${response.body}');
    }
  }

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Column(
                  children: [
                    Container(
                      color: const Color(0xFF564843),
                      height: MediaQuery.of(context).padding.top + 80,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 60),
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()),
                      );
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
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/winking-face.png',
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'EXPECTATIONS',
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            color: const Color(0xFF5B4436),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F8), // พื้นหลังชมพูอ่อน
                        border: Border.all(
                          color: const Color(0xFFC98993), // กรอบชมพู
                          width: 1.5,
                        ),
                        borderRadius:
                            BorderRadius.circular(16), // มุมโค้งมน น่ารัก ๆ
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.favorite, // ใช้หัวใจเพิ่มความน่ารัก
                            color: Color(0xFFC98993),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              expectationController.text.isNotEmpty
                                  ? expectationController.text
                                  : 'ไม่มีข้อมูลความคาดหวัง',
                              style: GoogleFonts.kanit(
                                fontSize: 15,
                                color: const Color(0xFF5B4436),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/persent.png',
                              width: 30,
                              height: 30,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'เปอร์เซ็นต์ความคาดหวังของคุณ',
                              style: GoogleFonts.kanit(
                                  fontSize: 18,
                                  color: const Color(0xFF5B4436),
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _percent != null
                          ? '${_percent!.toStringAsFixed(1)}%'
                          : 'รอคำนวณ...',
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5B4436),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'คุณทำได้ดีมาก! เก็บสถิติของตัวเองและความยินดีด้วย\nหวังว่าครั้งต่อไปจะดีกว่าเดิมนะคะ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: const Color(0xFF5B4436),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
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

  Widget _buildNavItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF5B4436)),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.kanit(
            color: const Color(0xFF5B4436),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
