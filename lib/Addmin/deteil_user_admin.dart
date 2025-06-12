import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/Addmin/edit_user.dart';
import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/main_Addmin.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainAddmin()),
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
          MaterialPageRoute(builder: (context) => const ListuserDeleteAdmin()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListuserPetition()),
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

          const SizedBox(height: 24),

          // Profile Box
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAE3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/icons/cat.jpg'),
                      ),
                      const SizedBox(height: 16),

                      // User info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECD8D3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            infoRow('Name :', 'ไอ้อ้วน'),
                            infoRow('Email :', 'Nutty'),
                            infoRow('Birthday :', '21/10/2202'),
                            infoRow('Password :', 'Nutty1234'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons
                      actionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserProfileEditPage(),
                            ),
                          );
                        },
                        icon: Image.asset(
                          'assets/icons/account.png',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
                        label: 'แก้ไขข้อมูลผู้ใช้',
                        color: const Color(0xFF59443F),
                      ),
                      const SizedBox(height: 10),
                      actionButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              int selectedIndex =
                                  -1; // -1 ยังไม่เลือก, 0=ไม่, 1=ใช่

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    backgroundColor: const Color(0xFFE6D2CD),
                                    title: Text(
                                      'ยืนยันการระงับบัญชี',
                                      style: GoogleFonts.kanit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF564843),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    content: Text(
                                      'ต้องการระงับบัญชีผู้ใช้คนนี้ใช่มั้ย?',
                                      style: GoogleFonts.kanit(
                                        fontSize: 18,
                                        color: const Color(0xFF3E3E3E),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    actionsAlignment: MainAxisAlignment.center,
                                    actionsPadding:
                                        const EdgeInsets.only(bottom: 12),
                                    actions: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selectedIndex == 0
                                              ? const Color(0xFF564843)
                                              : const Color(0xFFC98993),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 28, vertical: 12),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedIndex = 0;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'ไม่',
                                          style: GoogleFonts.kanit(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selectedIndex == 1
                                              ? const Color(0xFF564843)
                                              : const Color(0xFFC98993),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 28, vertical: 12),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedIndex = 1;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'ใช่',
                                          style: GoogleFonts.kanit(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        icon: Image.asset(
                          'assets/icons/deactivate.png',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
                        label: 'ระงับบัญชีผู้ใช้',
                        color: const Color(0xFF59443F),
                      ),

                      const SizedBox(height: 10),
                      actionButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              int selectedIndex = -1;

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    backgroundColor: const Color(0xFFE6D2CD),
                                    title: Text(
                                      'ยืนยันการลบบัญชี',
                                      style: GoogleFonts.kanit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF564843),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    content: Text(
                                      'คุณต้องการลบบัญชีผู้ใช้คนนี้ใช่มั้ย?',
                                      style: GoogleFonts.kanit(
                                        fontSize: 18,
                                        color: const Color(0xFF3E3E3E),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    actionsAlignment: MainAxisAlignment.center,
                                    actionsPadding:
                                        const EdgeInsets.only(bottom: 12),
                                    actions: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selectedIndex == 0
                                              ? const Color(0xFF564843)
                                              : const Color(0xFFC98993),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 28, vertical: 12),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedIndex = 0;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'ไม่',
                                          style: GoogleFonts.kanit(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selectedIndex == 1
                                              ? const Color(0xFF564843)
                                              : const Color(0xFFC98993),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 28, vertical: 12),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedIndex = 1;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'ใช่',
                                          style: GoogleFonts.kanit(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        icon: Image.asset(
                          'assets/icons/delete.png',
                          width: 23,
                          height: 23,
                        ),
                        label: 'ลบบัญชีผู้ใช้',
                        color: const Color(0xFF59443F),
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
            icon: Image.asset('assets/icons/deactivate.png',
                width: 30, height: 30),
            label: 'บัญชีที่ระงับ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/deleat.png', width: 24, height: 24),
            label: 'บัญชีที่ลบ',
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

  // Function สำหรับแถวข้อมูล
  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(140),
          1: FlexColumnWidth(),
        },
        children: [
          TableRow(
            children: [
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        color: const Color(0xFF3E3E3E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        color: const Color(0xFF3E3E3E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Function สำหรับปุ่ม
  Widget actionButton({
    required VoidCallback onPressed,
    required Widget icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(
        label,
        style: GoogleFonts.kanit(fontSize: 16, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
