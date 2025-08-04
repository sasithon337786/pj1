import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';
import 'package:pj1/user_expectations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pj1/constant/api_endpoint.dart';

class ExpectationScreen extends StatefulWidget {
  final int actId;
  const ExpectationScreen({
    super.key,
    required this.actId,
  });

  @override
  State<ExpectationScreen> createState() => _ExpectationScreenState();
}

class _ExpectationScreenState extends State<ExpectationScreen> {
  int _selectedIndex = 0;
  final TextEditingController expectationController = TextEditingController();
  final TextEditingController percentageController = TextEditingController();
  @override
  void dispose() {
    expectationController.dispose();
    percentageController.dispose();
    super.dispose();
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

  Future<void> _submitExpectation() async {
    final String expectationValue = expectationController.text;
    final String percentageValue = percentageController.text;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    if (expectationValue.isEmpty || percentageValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    try {
      final url = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/expuser/createexp'); // 🔁 เปลี่ยน IP ตามเครื่อง backend
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "act_id":  widget.actId, // 🟡 แก้ให้ตรงกับกิจกรรมของจริง
          "uid": uid, // 🟡 แก้ให้ตรงกับผู้ใช้ที่ล็อกอิน
          "user_exp": expectationValue,
          "percentage_exp": double.parse(percentageValue),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกความคาดหวังเรียบร้อย')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ExpectationResultScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อไม่ได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วน header UI
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
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: const Color(0xFFEFEAE3),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/winking-face.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EXPECTATIONS',
                            style: GoogleFonts.kanit(
                              fontSize: 18,
                              color: const Color(0xFF5B4436),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: expectationController,
                        style: GoogleFonts.kanit(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Input your expectations....',
                          hintStyle: GoogleFonts.kanit(
                            color: const Color(0xFFDEB3B3),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFE8C9C9),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/persent.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'เปอร์เซ็นต์ความคาดหวังของคุณ',
                            style: GoogleFonts.kanit(
                              fontSize: 15,
                              color: const Color(0xFF5B4436),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: percentageController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.kanit(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'ใส่เปอร์เซ็นต์ความคาดหวังของคุณ....',
                          hintStyle: GoogleFonts.kanit(
                            color: const Color(0xFFDEB3B3),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFE8C9C9),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: _submitExpectation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF564843),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Confirm',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
}
