import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/Addmin/add_admin.dart';
import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/main_Addmin.dart';

import 'package:pj1/add.dart'; // import หน้าจัดการข้อมูลแอปพลิเคชันใหม่

class ListuserDeleteAdmin extends StatefulWidget {
  const ListuserDeleteAdmin({Key? key}) : super(key: key);

  @override
  State<ListuserDeleteAdmin> createState() => _ListuserDeleteAdminState();
}

class _ListuserDeleteAdminState extends State<ListuserDeleteAdmin> {
  // ไม่ต้องมี List<String> users แล้ว เพราะจะไม่แสดงรายชื่อแล้ว
  // final List<String> users = ['Nutty', 'แฟรงค์', 'Mozel', 'คิวคิวคิว'];

  int _selectedIndex =
      2; // กำหนดค่าเริ่มต้นให้เป็น index ของ 'บัญชีที่ลบ' (ซึ่งตอนนี้จะเปลี่ยนเป็น 'จัดการข้อมูลแอป')

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // ใช้ pushReplacement เพื่อไม่ให้มีหน้าซ้อนกันเยอะเกินไปเมื่อกด BottomNavBar
    // แต่ถ้าต้องการให้กด back กลับมาได้ ให้ใช้ Navigator.push
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
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ListuserPetition()),
        );
        break;
    }
  }

  // ฟังก์ชันสำหรับไปหน้า "จัดการข้อมูลแอปพลิเคชัน"
  void _navigateToManageAppData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MainHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Column(
        children: [
          // Header UI (คงเดิม)
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

          Expanded(
            // ใช้ Column ภายใน Expanded เพื่อควบคุมการจัดเรียง
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.start, // จัดเรียงให้อยู่ด้านบน
              crossAxisAlignment:
                  CrossAxisAlignment.center, // จัดให้อยู่ตรงกลางแนวนอน
              children: [
                const SizedBox(height: 40), // เพิ่มระยะห่างจากขอบบนเล็กน้อย
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0), // Padding รอบ Card
                  child: Card(
                    color: const Color(0xFFEFEAE3), // สีพื้นหลังของ Card
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8, // เพิ่มเงาให้ Card ดูมีมิติ
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min, // ทำให้ Column เล็กพอดีเนื้อหา
                        children: [
                          // ไอคอนหรือข้อความบ่งบอก
                          Image.asset(
                            'assets/icons/winking-face.png', // ไอคอนที่คุณระบุ
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'จัดการข้อมูลแอปพลิเคชัน',
                            style: GoogleFonts.kanit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF564843),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity, // ทำให้ปุ่มกว้างเต็ม Card
                            child: ElevatedButton(
                              onPressed:
                                  _navigateToManageAppData, // เรียกฟังก์ชันไปหน้าจัดการข้อมูล
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFC98993), // สีปุ่ม
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5, // เพิ่มเงาให้ปุ่ม
                              ),
                              child: Text(
                                'จัดการข้อมูลแอปพลิเคชัน',
                                style: GoogleFonts.kanit(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
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
          // ** สิ้นสุดส่วน Content ที่เปลี่ยนแปลงไป **
        ],
      ),

      // Bottom Navigation Bar (คงเดิม, แค่เปลี่ยน label ของ index 2)
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
            icon: Image.asset('assets/icons/deactivate.png',
                width: 30, height: 30),
            label: 'บัญชีที่ระงับ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/social-media-management.png',
                width: 24, height: 24), // เปลี่ยนไอคอน
            label: 'Manage', // เปลี่ยนข้อความ
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/wishlist-heart.png',
                width: 24, height: 24),
            label: 'คำร้อง',
          ),
        ],
      ),
    );
  }
}
