import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/Addmin/deteil_user_admin.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/account.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  int _selectedIndex = 0;

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
          MaterialPageRoute(builder: (context) => const ListuserSuspended()),
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
            const SizedBox(height: 16),
            // กล่องข้อมูลผู้ใช้
            // กล่องข้อมูลผู้ใช้
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16), // เว้นขอบซ้าย-ขวา
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              width: double.infinity, // เต็มจอ (ลบแค่ margin)
              decoration: BoxDecoration(
                color: const Color(0xFFEFEAE3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Avatar
                  const CircleAvatar(
                    radius: 50, // ใหญ่ขึ้นนิดนึง
                    backgroundImage: AssetImage('assets/icons/cat.jpg'),
                  ),
                  const SizedBox(height: 16),
                  // ชื่อผู้ใช้
                  Text(
                    'ไอ้อ้วน',
                    style: GoogleFonts.kanit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF564843),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // กล่องข้อมูลกิจกรรม
                  Container(
                    width: double.infinity, // ให้เต็มกล่อง
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECD8D3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'กิจกรรมที่ผู้ใช้ทำทั้งหมด :  10',
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            color: const Color(0xFF564843),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'กิจกรรมที่ผู้ใช้ทำสำเร็จ :  6',
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            color: const Color(0xFF564843),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'กิจกรรมที่ผู้ใช้ทำไม่สำเร็จ :  4',
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            color: const Color(0xFF564843),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // ปุ่มข้อมูลผู้ใช้
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserDetailPage()),
                      );
                    },
                    icon: Image.asset(
                      'assets/icons/account.png',
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      'ข้อมูลผู้ใช้',
                      style: GoogleFonts.kanit(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF59443F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  )
                ],
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
              icon:
                  Image.asset('assets/icons/accout.png', width: 24, height: 24),
              label: 'User',
            ),
            BottomNavigationBarItem(
              icon: Image.asset('assets/icons/deactivate.png',
                  width: 30, height: 30),
              label: 'บัญชีที่ระงับ',
            ),
            BottomNavigationBarItem(
              icon:
                  Image.asset('assets/icons/deleat.png', width: 24, height: 24),
              label: 'บัญชีที่ลบ',
            ),
            BottomNavigationBarItem(
              icon: Image.asset('assets/icons/wishlist-heart.png',
                  width: 24, height: 24),
              label: 'คำร้อง',
            ),
          ],
        ));
  }
}
