import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/add.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/target.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          Column(
            children: [
              // สีด้านบน (แถบสีเข้ม)
              Container(
                height: MediaQuery.of(context).padding.top + 70,
                color: const Color(0xFF564843),
              ),
              const SizedBox(height: 54), // สำหรับโลโก้ลอย
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                AssetImage('assets/images/boy.png'),
                          ),
                          const SizedBox(height: 20),
                          buildUserRow("Name", "Nutty"),
                          buildUserRow("Email", "nutty337786"),
                          buildUserRow("Birthday", "21 June 2004"),
                          buildUserRow("Password", "nutty332547"),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              // ตรงนี้ใส่คำสั่งแก้ไขข้อมูลได้
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF564843),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.edit,
                                size: 18, color: Colors.white),
                            label: Text(
                              'แก้ไขข้อมูลส่วนตัว',
                              style: GoogleFonts.kanit(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ปุ่ม ส่งคำร้อง อยู่นอก Container ด้านบน
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // ตรงนี้ใส่คำสั่งส่งคำร้องได้
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF564843),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.person, color: Colors.white),
                  label: Text(
                    'ส่งคำร้อง',
                    style: GoogleFonts.kanit(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          // โลโก้บนสุด
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

  Widget buildUserRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '$label : ',
            style: GoogleFonts.kanit(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.kanit(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
