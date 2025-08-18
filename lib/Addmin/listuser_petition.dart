import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pj1/Addmin/deteiluser_suspended.dart';
import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/models/ReportModel.dart'; 

class ListuserPetition extends StatefulWidget {
  const ListuserPetition({Key? key}) : super(key: key);

  @override
  State<ListuserPetition> createState() => _ListuserPetitionState();
}

class _ListuserPetitionState extends State<ListuserPetition> {
  List<ReportModel> reports = [];
  bool isLoading = true;
  int _selectedIndex = 3; // กำหนดให้เมนู 'คำร้อง' เป็นเมนูที่ถูกเลือกเริ่มต้น

  @override
  void initState() {
    super.initState();
    fetchReports(); // เรียกใช้ฟังก์ชันดึงข้อมูลเมื่อ Widget ถูกสร้าง
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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
          MaterialPageRoute(builder: (context) => const ListuserDeleteAdmin()),
        );
        break;
      case 3:
        // อยู่ที่หน้าเดิม ไม่ต้องทำอะไร
        break;
    }
  }

  Future<void> fetchReports() async {
    setState(() {
      isLoading = true;
    });

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/report/getReport'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> jsonList = responseData['data'];
        if (mounted) {
          setState(() {
            reports = jsonList.map((json) => ReportModel.fromJson(json)).toList();
          });
        }
      } else {
        print('Failed to load reports: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถดึงข้อมูลคำร้องได้')),
          );
        }
      }
    } catch (e) {
      print('Error fetching reports: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Column(
        children: [
          // Header UI
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
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF564843),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/icons/admin.png',
                          width: 20, height: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Addmin',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Content User List
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAE3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/penti.png',
                            width: 35,
                            height: 35,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'รายการคำร้องของผู้ใช้',
                            style: GoogleFonts.kanit(
                              fontSize: 22,
                              color: const Color(0xFF564843),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // รายการ Reports
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : reports.isEmpty
                              ? Center(
                                  child: Text(
                                    'ไม่มีคำร้องที่รอดำเนินการ',
                                    style: GoogleFonts.kanit(fontSize: 16),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: reports.length,
                                  itemBuilder: (context, index) {
                                    final report = reports[index];
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF564843),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ชื่อผู้ใช้: ${report.username}',
                                                style: GoogleFonts.kanit(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'คำร้อง: ${report.reportDetail}',
                                                style: GoogleFonts.kanit(
                                                  fontSize: 16,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => DeteiluserSuspended(
                                                    userName: report.username,
                                                    // สามารถส่งข้อมูลอื่นๆ ที่จำเป็นได้ที่นี่ เช่น report.uid, report.reportDetail
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFE6D2CD),
                                              foregroundColor: const Color(0xFF564843),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                              textStyle: const TextStyle(fontSize: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Text(
                                              'ดูข้อมูลคำร้อง',
                                              style: GoogleFonts.kanit(
                                                fontSize: 15,
                                                color: const Color(0xFF564843),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFE6D2CD),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        selectedFontSize: 17,
        unselectedFontSize: 17,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedLabelStyle: GoogleFonts.kanit(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        unselectedLabelStyle: GoogleFonts.kanit(
          fontSize: 17,
          fontWeight: FontWeight.normal,
          color: Colors.white60,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/accout.png', width: 24, height: 24),
            label: 'User',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/deactivate.png', width: 30, height: 30),
            label: 'บัญชีที่ระงับ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/social-media-management.png', width: 24, height: 24),
            label: 'Manage',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/wishlist-heart.png', width: 24, height: 24),
            label: 'คำร้อง',
          ),
        ],
      ),
    );
  }
}